/* Barcode scanning.

   Native BarcodeDetector where available (Chrome/Android — fast, no bundle),
   ZXing from CDN as fallback (iOS Safari, older Android).

   The diagnostic below is deliberate: the most common reason a prototype
   "works on the laptop but not the phone" is being served over http://, which
   hard-blocks camera access on every modern browser except via localhost.
   Rather than fail silently the way most builds do, we name the cause. */

const FORMATS = ['ean_13', 'upc_a', 'ean_8', 'upc_e', 'code_128'];
const ZXING_CDN = 'https://cdn.jsdelivr.net/npm/@zxing/library@0.21.3/umd/index.min.js';

export function diagnose() {
  const { protocol, hostname } = location;

  if (!window.isSecureContext) {
    return {
      ok: false,
      title: 'Camera blocked — insecure connection',
      detail: `This page is served over <code>${protocol}//${hostname}</code>. Browsers ` +
        'block camera access entirely on non-HTTPS origins, with the single exception of ' +
        '<code>localhost</code>. No code change fixes this — the page has to be served ' +
        'over <code>https://</code>. <b>This is the most likely reason the original ' +
        'prototype scanned on the laptop but not on the phone.</b>',
    };
  }

  if (!navigator.mediaDevices?.getUserMedia) {
    return {
      ok: false,
      title: 'Camera API unavailable',
      detail: 'This browser does not expose <code>getUserMedia</code>. Try Chrome or Safari.',
    };
  }

  const engine = 'BarcodeDetector' in window ? 'native BarcodeDetector' : 'ZXing fallback';
  return {
    ok: true,
    title: 'Secure context — camera available',
    detail: `Served over HTTPS. Scanning engine: <b>${engine}</b>. ` +
      `Formats: ${FORMATS.join(', ')}.`,
  };
}

let stream = null;
let loopId = null;
let zxingReader = null;

function loadScript(src) {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) return resolve();
    const el = document.createElement('script');
    el.src = src;
    el.onload = resolve;
    el.onerror = () => reject(new Error('Failed to load scanning library'));
    document.head.appendChild(el);
  });
}

async function startNative(video, onDetect) {
  const supported = await window.BarcodeDetector.getSupportedFormats();
  const formats = FORMATS.filter((f) => supported.includes(f));
  if (!formats.length) throw new Error('No usable barcode formats');

  const detector = new window.BarcodeDetector({ formats });

  stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode: { ideal: 'environment' }, width: { ideal: 1280 } },
  });
  video.srcObject = stream;
  await video.play();

  let last = 0;
  const tick = async () => {
    if (!stream) return;
    const now = performance.now();
    if (now - last > 180) {
      last = now;
      try {
        const [hit] = await detector.detect(video);
        if (hit?.rawValue) { onDetect(hit.rawValue); return; }
      } catch { /* transient decode failure — keep scanning */ }
    }
    loopId = requestAnimationFrame(tick);
  };
  loopId = requestAnimationFrame(tick);
}

async function startZXing(video, onDetect) {
  await loadScript(ZXING_CDN);
  if (!window.ZXing) throw new Error('Scanning library unavailable');

  zxingReader = new window.ZXing.BrowserMultiFormatReader();
  await zxingReader.decodeFromConstraints(
    { video: { facingMode: { ideal: 'environment' } } },
    video,
    (result) => { if (result) onDetect(result.getText()); }
  );
}

export async function start(video, onDetect) {
  const check = diagnose();
  if (!check.ok) throw new Error(check.title);

  /* iOS Safari forces fullscreen without these and the scanner stalls. */
  video.setAttribute('playsinline', '');
  video.setAttribute('muted', '');
  video.muted = true;

  if ('BarcodeDetector' in window) {
    try { return await startNative(video, onDetect); }
    catch { stop(); /* fall through to ZXing */ }
  }
  return startZXing(video, onDetect);
}

export function stop() {
  if (loopId) { cancelAnimationFrame(loopId); loopId = null; }
  if (zxingReader) { try { zxingReader.reset(); } catch {} zxingReader = null; }
  if (stream) { stream.getTracks().forEach((t) => t.stop()); stream = null; }
}
