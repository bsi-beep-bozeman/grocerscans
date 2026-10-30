import {createServer} from 'node:http';
import {readFile,realpath,writeFile} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const mode=process.argv[2];if(!['app','storage'].includes(mode))throw Error('Choose approved app or storage output');
const root=await realpath(resolve('.cache/ch10-receiving-validation/web-'+mode));
if(!root.toLowerCase().startsWith((await realpath(process.cwd())).toLowerCase()+sep))throw Error('Output escapes workspace');
const types={'.html':'text/html','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.css':'text/css'};
const server=createServer(async(req,res)=>{
 try{const p=decodeURIComponent(new URL(req.url,'http://127.0.0.1:8136').pathname);const file=await realpath(resolve(root,'.'+(p==='/'?'/index.html':p)));if(!file.startsWith(root+sep)){res.writeHead(403).end();return;}res.writeHead(200,{'Content-Type':types[extname(file)]??'application/octet-stream','Cache-Control':'no-store'});res.end(await readFile(file));}catch{res.writeHead(404).end();}
});
server.listen(8136,'127.0.0.1',async()=>{await writeFile(resolve('.cache/ch10-receiving-validation/server-owner.json'),JSON.stringify({pid:process.pid,mode,root,port:8136,host:'127.0.0.1'}));console.log('Approved '+mode+' validation server at127.0.0.1:8136');});
