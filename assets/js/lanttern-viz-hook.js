import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { MeshLine, MeshLineMaterial, MeshLineRaycast } from 'three.meshline';

const RADIUS = 100;
const DIST = 24;

const layerCurve = new THREE.EllipseCurve(
  0, 0,            // ax, aY
  RADIUS, RADIUS,           // xRadius, yRadius
  0, 2 * Math.PI,  // aStartAngle, aEndAngle
  false,            // aClockwise
  0                 // aRotation
);

const layerPoints = layerCurve.getPoints(50);
const LAYER_GEOMETRY = new THREE.BufferGeometry().setFromPoints(layerPoints);

const SPHERE_GEOMETRY = new THREE.SphereGeometry(RADIUS / 25, 20, 20);

function drawCurve(scene, z, layerMaterials, isMoment = true) {
  let ellipse;

  if (isMoment) {
    const material = layerMaterials.moment;
    ellipse = new THREE.Line(LAYER_GEOMETRY, material);
    ellipse.computeLineDistances();
  } else {
    const line = new MeshLine();
    line.setGeometry(LAYER_GEOMETRY);
    const material = layerMaterials.final;
    ellipse = new THREE.Mesh(line, material);
  }

  ellipse.position.z = z;

  scene.add(ellipse);
}

function drawSphere(scene, x, y, z, material) {
  const sphere = new THREE.Mesh(SPHERE_GEOMETRY, material);
  sphere.position.x = x;
  sphere.position.y = y;
  sphere.position.z = z;

  scene.add(sphere);
}

function drawLayer(scene, assessmentPoints, z, layerMaterials, sphereMaterials, layerIndex, currentItems) {
  if (layerIndex === 0) {
    drawCurve(scene, z, layerMaterials, false);
  } else {
    drawCurve(scene, z, layerMaterials);
  }

  const radiansZAndIndex = [];

  assessmentPoints
    .forEach((ap, i) => {
      if (currentItems.length === 0 || currentItems.includes(ap)) {
        const a = (2 * Math.PI / assessmentPoints.length) * i;
        const x = Math.cos(a) * RADIUS;
        const y = Math.sin(a) * RADIUS;
        drawSphere(scene, x, y, z, sphereMaterials[ap]);

        radiansZAndIndex.push([ap, a, z, layerIndex]);
      }
    });

  return radiansZAndIndex;
}

function drawConnection(scene, r1, z1, r2, z2, material) {
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

function buildViz(canvas, momentsAssessmentPoints) {
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

  return scene;
}

function drawViz(scene, strandGoals, momentsAssessmentPoints, layerMaterials, sphereMaterials, connectionMaterials, currentItems = []) {
  clearThree(scene);
  const goalsRadiansZAndIndex = drawLayer(scene, strandGoals, 0, layerMaterials, sphereMaterials, 0, currentItems);

  const momentsRadiansZAndIndex = [];
  momentsAssessmentPoints.forEach((momentAssessmentPoints, i) => {
    momentsRadiansZAndIndex.push(
      drawLayer(scene, momentAssessmentPoints, -DIST * (i + 1), layerMaterials, sphereMaterials, i + 1, currentItems)
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
          connections.push([lastRad, lastZ, mRad, mZ, connectionMaterials[id]]);
          lastRadZAndIndexByItem[id] = [mRad, mZ, mI];
        }
      }
    }
  }

  connections.forEach(([r1, z1, r2, z2, material]) => {
    drawConnection(scene, r1, z1, r2, z2, material);
  });
}

function buildLayerMaterials() {
  return {
    moment: new THREE.LineDashedMaterial({ color: 0xe2e8f0, dashSize: 1, gapSize: 3 }),
    final: new MeshLineMaterial({ color: 0x334155, lineWidth: 0.5 })
  };
}

function buildSphereMaterials(colorMap) {
  const sphereMaterials = {};

  for (const id in colorMap) {
    color = colorMap[id];
    sphereMaterials[id] = new THREE.MeshBasicMaterial({ color });
  }

  return sphereMaterials;
}

function buildConnectionMaterials(colorMap) {
  const connectionMaterials = {};

  for (const id in colorMap) {
    color = colorMap[id];
    connectionMaterials[id] = new MeshLineMaterial({ color });
  }

  return connectionMaterials;
}

const lantternVizHook = {
  mounted() {
    const canvas = this.el;

    let scene, strandGoals, momentsAssessmentPoints;
    let sphereMaterials, connectionMaterials;
    let currentItems = [];

    const layerMaterials = buildLayerMaterials();

    this.handleEvent("build_lanttern_viz", data => {
      const {
        strand_goals_curriculum_items_ids,
        moments_assessments_curriculum_items_ids,
        curriculum_items_ids_color_map
      } = data;

      strandGoals = strand_goals_curriculum_items_ids;
      momentsAssessmentPoints = moments_assessments_curriculum_items_ids;

      sphereMaterials = buildSphereMaterials(curriculum_items_ids_color_map);
      connectionMaterials = buildConnectionMaterials(curriculum_items_ids_color_map);

      scene = buildViz(canvas, momentsAssessmentPoints);
      drawViz(scene, strandGoals, momentsAssessmentPoints, layerMaterials, sphereMaterials, connectionMaterials);
    });

    this.handleEvent("set_current_item", ({ id: itemId }) => {
      if (currentItems.includes(itemId)) {
        currentItems = currentItems.filter(id => id != itemId);
        drawViz(scene, strandGoals, momentsAssessmentPoints, layerMaterials, sphereMaterials, connectionMaterials, currentItems);
      } else {
        currentItems = [...currentItems, itemId];
        drawViz(scene, strandGoals, momentsAssessmentPoints, layerMaterials, sphereMaterials, connectionMaterials, currentItems);
      }
    });
  },
};

export default lantternVizHook;
