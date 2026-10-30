import {createServer} from 'node:http';
import {readFile,realpath,writeFile} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const root=await realpath(resolve(import.meta.dirname,'../../../.cache/client-dry-run/release'));
const config=JSON.parse(await readFile(resolve(root,'vercel.json'),'utf8'));
const headers=Object.fromEntries(config.headers[0].headers.map(h=>[h.key,h.value]));
const types={'.html':'text/html; charset=utf-8','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.css':'text/css','.txt':'text/plain'};
const server=createServer(async(req,res)=>{
  try{const path=decodeURIComponent(new URL(req.url,'http://127.0.0.1:8137').pathname);const file=await realpath(resolve(root,'.'+(path==='/'?'/index.html':path)));
    if(!file.startsWith(root+sep)){res.writeHead(403).end();return;}
    res.writeHead(200,{...headers,'Content-Type':types[extname(file)]??'application/octet-stream'});res.end(await readFile(file));
  }catch{res.writeHead(404).end('Not found');}
});
server.listen(8137,'127.0.0.1',async()=>{await writeFile(resolve(root,'../server-owner.json'),JSON.stringify({pid:process.pid,root,port:8137,host:'127.0.0.1'}));console.log('Client dry run: http://127.0.0.1:8137');});
