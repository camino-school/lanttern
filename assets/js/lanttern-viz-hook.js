import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const RADIUS = 100;
const DIST = 24;

const PALETTE = [
  0X67e8f9, // cyan
  0xfda4af, // rose
  0xc4b5fd, // violet
  0xfde047, // yellow
  0xbef264, // lime
  0x93c5fd, // blue
  0xf0abfc, // fuschia
  0xfdba74, // orange
];

function drawCurve(scene, z) {
  const curve = new THREE.EllipseCurve(
    0, 0,            // ax, aY
    RADIUS, RADIUS,           // xRadius, yRadius
    0, 2 * Math.PI,  // aStartAngle, aEndAngle
    false,            // aClockwise
    0                 // aRotation
  );

  const points = curve.getPoints(50);
  const geometry = new THREE.BufferGeometry().setFromPoints(points);

  const material = new THREE.LineDashedMaterial({ color: 0xe2e8f0, dashSize: 2, gapSize: 4 });

  const ellipse = new THREE.Line(geometry, material);
  ellipse.computeLineDistances();
  ellipse.position.z = z;

  scene.add(ellipse);
}

function drawSphere(scene, x, y, z, color) {
  const geometry = new THREE.SphereGeometry(RADIUS / 25, 20, 20);
  const material = new THREE.MeshBasicMaterial({ color });
  const sphere = new THREE.Mesh(geometry, material);
  sphere.position.x = x;
  sphere.position.y = y;
  sphere.position.z = z;

  scene.add(sphere);
}

function drawLayer(scene, assessmentPoints, z, colorMap, angleShift, currentItem) {
  drawCurve(scene, z);

  const radiansAndZ = [];

  assessmentPoints
    .forEach((ap, i) => {
      if (!currentItem || ap === currentItem) {
        const a = (2 * Math.PI / assessmentPoints.length) * i + angleShift;
        const x = Math.cos(a) * RADIUS;
        const y = Math.sin(a) * RADIUS;
        drawSphere(scene, x, y, z, colorMap[ap]);

        radiansAndZ.push([ap, a, z]);
      }
    });

  return radiansAndZ;
}

function drawConnection(scene, r1, z1, r2, z2, color) {
  const rStep = (r2 - r1) / 10;
  const zStep = (z2 - z1) / 10;

  const curvePoints = [];
  for (let i = 0; i <= 10; i++) {
    const r = r1 + (rStep * i);
    const z = z1 + (zStep * i);
    curvePoints.push(new THREE.Vector3(Math.cos(r) * RADIUS, Math.sin(r) * RADIUS, z));
  }

  const curve = new THREE.CatmullRomCurve3(curvePoints);
  const points = curve.getPoints(50);
  const geometry = new THREE.BufferGeometry().setFromPoints(points);

  const material = new THREE.LineBasicMaterial({ color });

  // Create the final object to add to the scene
  const connection = new THREE.Line(geometry, material);

  scene.add(connection);
}

function clearThree(obj) {
  while (obj.children.length > 0) {
    clearThree(obj.children[0]);
    obj.remove(obj.children[0]);
  }
  if (obj.geometry) obj.geometry.dispose();

  if (obj.material) {
    //in case of map, bumpMap, normalMap, envMap ...
    Object.keys(obj.material).forEach(prop => {
      if (!obj.material[prop])
        return;
      if (obj.material[prop] !== null && typeof obj.material[prop].dispose === 'function')
        obj.material[prop].dispose();
    });
    obj.material.dispose();
  }
}

function buildViz(canvas, strandGoals, momentsAssessmentPoints, currentItem = null) {
  const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, premultipliedAlpha: false, antialias: true });

  const fov = 40;
  const aspect = 2; // the canvas default
  const near = 0.1;
  const far = 5000;
  const camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
  camera.position.set(200, 0, 200);
  camera.up.set(0, 0, 1);
  camera.lookAt(0, 0, 0);

  const controls = new OrbitControls(camera, canvas);
  controls.target.set(0, 0, 0);
  controls.update();

  const scene = new THREE.Scene();

  colorMap = {};
  strandGoals.forEach((goal, i) => {
    colorMap[goal] = PALETTE[i % 8];
  });

  drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItem);

  // reposition scene based on moments length
  z = (DIST * momentsAssessmentPoints.length) / 2;
  scene.position.z = z;

  function render(time) {
    time *= 0.0001;

    function resizeCanvasToDisplaySize() {
      const canvas = renderer.domElement;
      const width = canvas.clientWidth;
      const height = canvas.clientHeight;

      renderer.setSize(width, height, false);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
    }

    const resizeObserver = new ResizeObserver(resizeCanvasToDisplaySize);
    resizeObserver.observe(canvas, { box: 'content-box' });

    const rot = time;
    scene.rotation.z = rot;

    renderer.render(scene, camera);
    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);

  return [scene, colorMap];
}

function drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItem) {
  clearThree(scene);
  const goalsRadiansAndZ = drawLayer(scene, strandGoals, 0, colorMap, 0, currentItem);

  const momentsRadiansAndZ = [];
  momentsAssessmentPoints.forEach((momentAssessmentPoints, i) => {
    const angleShift = Math.PI / 10 * (i + 1);
    momentsRadiansAndZ.push(
      drawLayer(scene, momentAssessmentPoints, -DIST * (i + 1), colorMap, angleShift, currentItem)
    );
  });

  const connections = [];
  const lastRadZByItem = {};

  for (const [id, rad, z] of goalsRadiansAndZ) {
    lastRadZByItem[id] = [rad, z];
    for (const m of momentsRadiansAndZ) {
      for (const [mId, mRad, mZ] of m) {
        if (id === mId) {
          [lastRad, lastZ] = lastRadZByItem[id];
          connections.push([lastRad, lastZ, mRad, mZ, colorMap[id]]);
          lastRadZByItem[id] = [mRad, mZ];
        }
      }
    }
  }

  connections.forEach(([r1, z1, r2, z2, color]) => {
    drawConnection(scene, r1, z1, r2, z2, color);
  });
}

const lantternVizHook = {
  mounted() {
    const canvas = this.el;

    let data, currentItem, scene, colorMap, strandGoals, momentsAssessmentPoints;

    this.handleEvent("build_lanttern_viz", data => {
      const { strand_goals, moments_assessment_points } = data;
      strandGoals = strand_goals;
      momentsAssessmentPoints = moments_assessment_points;
      [scene, colorMap] = buildViz(canvas, strandGoals, momentsAssessmentPoints);
    });

    this.handleEvent("set_current_item", ({ id: itemId }) => {
      if (currentItem === itemId) {
        currentItem = null;
        drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItem);
      } else {
        currentItem = itemId;
        drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItem);
      }
    });
  },
};

export default lantternVizHook;
