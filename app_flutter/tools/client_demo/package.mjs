import {readFile,writeFile,mkdir,readdir,copyFile} from 'node:fs/promises';
import {resolve,join,relative,sep} from 'node:path';
import {createHash} from 'node:crypto';

const root=resolve(import.meta.dirname,'../../..');
const build=join(root,'.cache/client-dry-run/web');
const release=join(root,'.cache/client-dry-run/release');
const evidence=join(root,'handoffs/2026-10-30/client-dry-run');
await mkdir(release,{recursive:true}); await mkdir(evidence,{recursive:true});
const excluded=new Set(['flutter_service_worker.js']);
async function copy(dir){
  for(const e of await readdir(dir,{withFileTypes:true})){
    const src=join(dir,e.name), name=relative(build,src);
    if(e.name.startsWith('.')||e.name.endsWith('.map')||e.name.endsWith('.symbols')||excluded.has(e.name)) continue;
    const dest=join(release,name);
    if(e.isDirectory()){await mkdir(dest,{recursive:true});await copy(src);}
    else {await copyFile(src,dest);}
  }
}
await copy(build);
const bootstrap=await readFile(join(build,'flutter_bootstrap.js'),'utf8');
const marker='_flutter.loader.load({';
if(!bootstrap.includes(marker))throw Error('Unexpected Flutter bootstrap');
await writeFile(join(release,'flutter_bootstrap.js'),bootstrap.slice(0,bootstrap.lastIndexOf(marker))+"_flutter.loader.load({config:{canvasKitBaseUrl:'canvaskit/'}});\n");
const headers=[
  {key:'X-Robots-Tag',value:'noindex, nofollow'},
  {key:'X-Content-Type-Options',value:'nosniff'},
  {key:'Referrer-Policy',value:'no-referrer'},
  {key:'Cache-Control',value:'no-store'},
  {key:'Content-Security-Policy',value:"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self'; connect-src 'self'; worker-src 'self' blob:; frame-ancestors 'none'; base-uri 'self'; form-action 'none'"},
];
await writeFile(join(release,'vercel.json'),JSON.stringify({version:2,buildCommand:null,installCommand:null,framework:null,headers:[{source:'/(.*)',headers}]},null,2));
await writeFile(join(release,'_headers'),'/*\n'+headers.map(h=>'  '+h.key+': '+h.value).join('\n')+'\n');
await writeFile(join(release,'robots.txt'),'User-agent: *\nDisallow: /\n');
await writeFile(join(release,'index.html'),`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><base href="/">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex,nofollow"><meta name="theme-color" content="#173b32">
<meta name="description" content="Try ShelfLife admin setup and staff receiving with a fictional practice store.">
<title>ShelfLife · Client dry run</title>
<style>body{margin:0;background:#f3f5f2;font-family:Arial,sans-serif;color:#173b32}#loading{padding:48px;max-width:540px;margin:10vh auto}h1{font-size:36px}p{line-height:1.6}a{color:inherit}</style>
</head><body><div id="loading"><h1>ShelfLife</h1><p>Opening your practice store…</p><p>Sample data · Admin and staff dry run</p><p><a href="client-guide.html">Read the dry-run guide</a></p></div>
<noscript>Enable JavaScript to open the interactive preview.</noscript><script src="demo-loader.js"></script><script src="flutter_bootstrap.js" async></script></body></html>`);
await writeFile(join(release,'demo-loader.js'),"window.addEventListener('flutter-first-frame',()=>document.getElementById('loading')?.remove());\n");
await writeFile(join(release,'client-guide.html'),`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>ShelfLife dry-run guide</title><style>body{font:18px/1.6 system-ui;max-width:760px;margin:auto;padding:24px;color:#173b32}li{margin:20px 0}a{color:inherit}small{font-size:15px}</style><h1>Your ShelfLife dry run</h1><p><a href="/">Open the practice store</a></p><p>This evaluation build uses fictional data. Each browser has its own saved practice work. The public practice PINs are simulated access, not real accounts.</p><ol><li><b>Admin:</b> Open admin setup, choose Market Street, change the store name, and Save draft. Explore the six steps.</li><li><b>Activate:</b> In Review &amp; activate, review activation, enter “Client dry run” and activate the configuration.</li><li><b>Staff:</b> Return to the demo. Open staff receiving. Alex’s PIN is <b>2468</b>. Search for milk, select Whole milk, enter quantity 6. Put a fictional delivery reference and printed expiry date in Notes; dedicated expiry entry is not built yet.</li><li><b>Persistence:</b> Save on this device. Wait for the saved message, lock and enter 2468 again. Open a saved draft. Refresh the page and repeat.</li><li><b>Different staff:</b> Lock and enter Sam’s PIN <b>1357</b>. Alex’s drafts should not appear. Return to Alex with 2468.</li><li><b>Repeat:</b> Use Reset practice data on the welcome page when ready to start over.</li></ol><h2>Tell us what you think</h2><p>What was clear? What slowed you down? What is missing from a real shift? Include the step, your device/browser, expected result, actual result and a screenshot when useful.</p><h2>Current limits</h2><p>Saved drafts do not receive stock or submit receipts. No shared live inventory, real authentication, automatic expiry calculations or camera scanning is tested here. Admin activation changes practice rules in this browser only. Use one tab at a time. Clearing site data removes practice work.</p><small>Evaluation build · 30 October 2026</small></html>`);
const manifest=[];
async function list(dir){for(const e of await readdir(dir,{withFileTypes:true})){const path=join(dir,e.name);if(e.isDirectory())await list(path);else {const bytes=await readFile(path);manifest.push({file:relative(release,path).split(sep).join('/'),size:bytes.length,sha1:createHash('sha1').update(bytes).digest('hex'),sha256:createHash('sha256').update(bytes).digest('hex')});}}}
await list(release);
await writeFile(join(evidence,'RELEASE_MANIFEST.json'),JSON.stringify({createdAt:new Date().toISOString(),entrypoint:'lib/client_demo.dart',files:manifest,totalBytes:manifest.reduce((n,f)=>n+f.size,0)},null,2));
console.log(JSON.stringify({release,files:manifest.length,totalBytes:manifest.reduce((n,f)=>n+f.size,0)}));
