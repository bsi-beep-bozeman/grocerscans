// Chapter 06 only: recreate stopped disposable containers with explicit host IPs.
// No credentials are logged. Original stopped containers are retained as backups.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {execFileSync} from 'node:child_process';

const project = 'shelflife-ch06-validation';
const privateDir = path.resolve('.cache/ch06-validation/private/rebind');
const docker = (...args) => execFileSync('docker', ['--context', 'desktop-linux', ...args], {encoding:'utf8', maxBuffer:8*1024*1024});
const api = (endpoint, body) => new Promise((resolve, reject) => {
  const payload = JSON.stringify(body);
  const req = http.request({socketPath:'\\\\.\\pipe\\dockerDesktopLinuxEngine',path:'/v1.56'+endpoint,method:'POST',headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(payload)}},res=>{
    let data=''; res.on('data',c=>data+=c); res.on('end',()=>{
      if(res.statusCode>=300) return reject(new Error('Docker create failed; HTTP '+res.statusCode));
      resolve(JSON.parse(data));
    });
  }); req.on('error',reject); req.end(payload);
});
const specs = [
  ['db', ['/etc/postgresql/postgresql.conf','/etc/postgresql.schema.sql','/etc/postgresql-custom/pgsodium_root.key']],
  ['kong', ['/home/kong']],
  ['inbucket', []],
];
fs.mkdirSync(privateDir,{recursive:true});
for(const [service,files] of specs) {
  const name=`supabase_${service}_${project}`, backup=name+'_binding_backup';
  const info=JSON.parse(docker('inspect',name))[0];
  if(info.State.Running || info.Name!=='/'+name) throw Error('Expected stopped disposable container');
  if(Object.keys(info.NetworkSettings.Networks).join()!==project) throw Error('Unexpected network');
  if(!info.Config.Image.startsWith('public.ecr.aws/supabase/')) throw Error('Unexpected image');
  if(docker('ps','-a','--filter','name=^/'+backup+'$','--format','{{.Names}}').trim()) throw Error('Backup already exists');
  const folder=path.join(privateDir,service); fs.mkdirSync(folder,{recursive:true});
  fs.writeFileSync(path.join(folder,'inspect.json'),JSON.stringify(info));
  for(let i=0;i<files.length;i++) docker('cp','-a',name+':'+files[i],path.join(folder,'file-'+i));
  const bindings=structuredClone(info.HostConfig.PortBindings);
  for(const entries of Object.values(bindings)) for(const b of entries) {
    if(!['55321','55322','55324'].includes(b.HostPort)) throw Error('Unexpected port');
    b.HostIp='127.0.0.1';
  }
  docker('rename',name,backup);
  const created=await api('/containers/create?name='+encodeURIComponent(name),{
    ...info.Config, Image:info.Image,
    HostConfig:{...info.HostConfig,PortBindings:bindings},
    NetworkingConfig:{EndpointsConfig:{[project]:{Aliases:info.NetworkSettings.Networks[project].Aliases}}},
  });
  for(let i=0;i<files.length;i++) {
    const local=path.join(folder,'file-'+i);
    docker('cp','-a',fs.statSync(local).isDirectory()?local+path.sep+'.':local,name+':'+files[i]);
  }
  const check=JSON.parse(docker('inspect',name))[0];
  for(const entries of Object.values(check.HostConfig.PortBindings)) for(const b of entries) if(b.HostIp!=='127.0.0.1') throw Error('Binding check failed');
  console.log(JSON.stringify({service,id:created.Id,bindings:check.HostConfig.PortBindings,originalRetained:backup}));
}
