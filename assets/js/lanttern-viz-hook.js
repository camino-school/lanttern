import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const RADIUS = 100;
const DIST = 24;

const PALETTE = [
  0Xef4444, // red
  0x10b981, // emerald
  0x6366f1, // indigo
  0xf59e0b, // amber
  0x06b6d4, // cyan
  0xd946ef, // fuchsia
  0x84cc16, // lime
  0xf43f5e, // rose
]

const PALETTE_SECONDARY = [
  0Xfecaca, // red
  0xa7f3d0, // emerald
  0xc7d2fe, // indigo
  0xfde68a, // amber
  0xa5f3fc, // cyan
  0xf5d0fe, // fuchsia
  0xd9f99d, // lime
  0xfecdd3, // rose
]

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

  const material = new THREE.LineDashedMaterial({ color: 0xe2e8f0, dashSize: 2, gapSize: 2 });

  const ellipse = new THREE.Line(geometry, material);
  ellipse.computeLineDistances()
  ellipse.position.z = z

  scene.add(ellipse);
}

function drawSphere(scene, x, y, z, color) {
  const geometry = new THREE.SphereGeometry(RADIUS / 25, 20, 20);
  const material = new THREE.MeshBasicMaterial({ color });
  const sphere = new THREE.Mesh(geometry, material);
  sphere.position.x = x
  sphere.position.y = y
  sphere.position.z = z

  scene.add(sphere);
}

function drawLayer(scene, assessmentPoints, z, colorMap, angleShift) {
  drawCurve(scene, z);

  const radiansAndZ = []

  assessmentPoints
    .forEach((ap, i) => {
      const a = (2 * Math.PI / assessmentPoints.length) * i + angleShift
      const x = Math.cos(a) * RADIUS
      const y = Math.sin(a) * RADIUS
      drawSphere(scene, x, y, z, colorMap[ap])

      radiansAndZ.push([ap, a, z])
    })

  return radiansAndZ
}

function drawConnection(scene, r1, z1, r2, z2, color) {
  const rStep = (r2 - r1) / 10
  const zStep = (z2 - z1) / 10

  const curvePoints = []
  for (let i = 0; i <= 10; i++) {
    const r = r1 + (rStep * i)
    const z = z1 + (zStep * i)
    curvePoints.push(new THREE.Vector3(Math.cos(r) * RADIUS, Math.sin(r) * RADIUS, z))
  }

  const curve = new THREE.CatmullRomCurve3(curvePoints);
  const points = curve.getPoints(50);
  const geometry = new THREE.BufferGeometry().setFromPoints(points);

  const material = new THREE.LineBasicMaterial({ color });

  // Create the final object to add to the scene
  const connection = new THREE.Line(geometry, material);

  scene.add(connection)
}

function buildViz(canvas, { strand_goals, moments_assessment_points }) {
  const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, premultipliedAlpha: false, antialias: true });

  const fov = 40;
  const aspect = 2; // the canvas default
  const near = 0.1;
  const far = 5000;
  const camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
  camera.position.set(400, 0, 300);
  camera.up.set(0, 0, 1);
  camera.lookAt(0, 0, 0);

  const controls = new OrbitControls(camera, canvas);
  controls.target.set(0, 0, 0);
  controls.update();

  const scene = new THREE.Scene();

  colorMap = {}
  secondaryColorMap = {}
  strand_goals.forEach((goal, i) => {
    colorMap[goal] = PALETTE[i % 8]
    secondaryColorMap[goal] = PALETTE_SECONDARY[i % 8]
  })

  const goalsRadiansAndZ = drawLayer(scene, strand_goals, 0, colorMap, 0)

  const momentsRadiansAndZ = []
  moments_assessment_points.forEach((moment_assessment_points, i) => {
    const angleShift = Math.PI / 10 * (i + 1)
    momentsRadiansAndZ.push(
      drawLayer(scene, moment_assessment_points, -DIST * (i + 1), secondaryColorMap, angleShift)
    );
  })

  const connections = []

  for (const [id, rad, z] of goalsRadiansAndZ) {
    for (const m of momentsRadiansAndZ) {
      for (const [mId, mRad, mZ] of m) {
        if (id === mId) {
          connections.push([rad, z, mRad, mZ, colorMap[id]])
        }
      }
    }
  }

  connections.forEach(([r1, z1, r2, z2, color]) => {
    drawConnection(scene, r1, z1, r2, z2, color)
  })

  // reposition scene based on moments length
  z = (DIST * moments_assessment_points.length) / 2
  scene.position.z = z

  function resizeRendererToDisplaySize(renderer) {
    const canvas = renderer.domElement;
    const pixelRatio = window.devicePixelRatio;
    const width = Math.floor(canvas.clientWidth * pixelRatio);
    const height = Math.floor(canvas.clientHeight * pixelRatio);
    const needResize = canvas.width !== width || canvas.height !== height;

    if (needResize) {
      renderer.setSize(width, height, false);
    }

    return needResize;
  }

  function render(time) {
    time *= 0.0001;

    if (resizeRendererToDisplaySize(renderer)) {
      const canvas = renderer.domElement;
      camera.aspect = canvas.clientWidth / canvas.clientHeight;
      camera.updateProjectionMatrix();
    }

    const rot = time;
    scene.rotation.z = rot;

    renderer.render(scene, camera);
    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);
}

const lantternVizHook = {
  mounted() {
    const canvas = this.el

    this.handleEvent("build_lanttern_viz", data => {
      buildViz(canvas, data);
    })
  },
};

export default lantternVizHook;
