import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { MeshLine, MeshLineMaterial, MeshLineRaycast } from 'three.meshline';

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

function drawCurve(scene, z, color = 0xe2e8f0, isDashed = true) {
  const curve = new THREE.EllipseCurve(
    0, 0,            // ax, aY
    RADIUS, RADIUS,           // xRadius, yRadius
    0, 2 * Math.PI,  // aStartAngle, aEndAngle
    false,            // aClockwise
    0                 // aRotation
  );

  const points = curve.getPoints(50);
  const geometry = new THREE.BufferGeometry().setFromPoints(points);

  let ellipse;

  if (isDashed) {
    const material = new THREE.LineDashedMaterial({ color, dashSize: 1, gapSize: 3 });
    ellipse = new THREE.Line(geometry, material);
    ellipse.computeLineDistances();
  } else {
    const line = new MeshLine();
    line.setGeometry(geometry);
    const material = new MeshLineMaterial({ color, lineWidth: 0.5 });
    ellipse = new THREE.Mesh(line, material);
  }

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

function drawLayer(scene, assessmentPoints, z, colorMap, layerIndex, currentItems) {
  if (layerIndex === 0) {
    drawCurve(scene, z, 0x334155, false);
  } else {
    drawCurve(scene, z);
  }

  const radiansZAndIndex = [];

  assessmentPoints
    .forEach((ap, i) => {
      if (currentItems.length === 0 || currentItems.includes(ap)) {
        const a = (2 * Math.PI / assessmentPoints.length) * i;
        const x = Math.cos(a) * RADIUS;
        const y = Math.sin(a) * RADIUS;
        drawSphere(scene, x, y, z, colorMap[ap]);

        radiansZAndIndex.push([ap, a, z, layerIndex]);
      }
    });

  return radiansZAndIndex;
}

function drawConnection(scene, r1, z1, r2, z2, color) {
  const rStep = (r2 - r1) / 20;
  const zStep = (z2 - z1) / 20;

  const curvePoints = [];
  for (let i = 0; i <= 20; i++) {
    const r = r1 + (rStep * i);
    const z = z1 + (zStep * i);
    curvePoints.push(new THREE.Vector3(Math.cos(r) * RADIUS, Math.sin(r) * RADIUS, z));
  }

  const curve = new THREE.CatmullRomCurve3(curvePoints);
  const points = curve.getPoints(50);
  const geometry = new THREE.BufferGeometry().setFromPoints(points);
  const line = new MeshLine();
  line.setGeometry(geometry);

  const material = new MeshLineMaterial({ color });

  // Create the final object to add to the scene
  const connection = new THREE.Mesh(line, material);

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

function buildViz(canvas, strandGoals, momentsAssessmentPoints, currentItems = []) {
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

  drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItems);

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
    scene.rotation.z = -rot;

    renderer.render(scene, camera);
    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);

  return [scene, colorMap];
}

function drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItems) {
  clearThree(scene);
  const goalsRadiansZAndIndex = drawLayer(scene, strandGoals, 0, colorMap, 0, currentItems);

  const momentsRadiansZAndIndex = [];
  momentsAssessmentPoints.forEach((momentAssessmentPoints, i) => {
    momentsRadiansZAndIndex.push(
      drawLayer(scene, momentAssessmentPoints, -DIST * (i + 1), colorMap, i + 1, currentItems)
    );
  });

  const connections = [];
  const lastRadZAndIndexByItem = {};
  const radShiftByItem = {};

  for (const [id, rad, z, i] of goalsRadiansZAndIndex) {
    lastRadZAndIndexByItem[id] = [rad, z, i];
    radShiftByItem[id] = 0;
    for (const m of momentsRadiansZAndIndex) {
      for (let [mId, mRad, mZ, mI] of m) {
        if (id === mId) {
          const [lastRad, lastZ, lastI] = lastRadZAndIndexByItem[id];
          if (mI !== lastI) {
            radShiftByItem[id] = radShiftByItem[id] + 2 * Math.PI;
          }
          mRad = mRad + radShiftByItem[id];
          connections.push([lastRad, lastZ, mRad, mZ, colorMap[id]]);
          lastRadZAndIndexByItem[id] = [mRad, mZ, mI];
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

    let scene, colorMap, strandGoals, momentsAssessmentPoints;
    let currentItems = [];

    this.handleEvent("build_lanttern_viz", data => {
      const { strand_goals_curriculum_items_ids, moments_assessments_curriculum_items_ids } = data;
      strandGoals = strand_goals_curriculum_items_ids;
      momentsAssessmentPoints = moments_assessments_curriculum_items_ids;
      [scene, colorMap] = buildViz(canvas, strandGoals, momentsAssessmentPoints);
    });

    this.handleEvent("set_current_item", ({ id: itemId }) => {
      if (currentItems.includes(itemId)) {
        currentItems = currentItems.filter(id => id != itemId);
        drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItems);
      } else {
        currentItems = [...currentItems, itemId];
        drawViz(scene, strandGoals, momentsAssessmentPoints, colorMap, currentItems);
      }
    });
  },
};

export default lantternVizHook;
