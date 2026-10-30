import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const root=resolve('.cache/ch06-validation/web');
const types={'.html':'text/html','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.css':'text/css'};
createServer(async(req,res)=>{
 try{
  const pathname=decodeURIComponent(new URL(req.url,'http://127.0.0.1').pathname);
  const file=resolve(root,'.'+(pathname==='/'?'/index.html':pathname));
  if(!file.startsWith(root+sep)){res.writeHead(403).end();return;}
  const body=await readFile(file);res.writeHead(200,{'Content-Type':types[extname(file)]??'application/octet-stream','Cache-Control':'no-store'}).end(body);
 }catch{res.writeHead(404).end('Not found');}
}).listen(8136,'127.0.0.1',()=>console.log('Chapter06 validation application on http://127.0.0.1:8136'));
