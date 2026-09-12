import {createServer} from 'node:http';
import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {validateSpeech, withinBudget} from './policy.mjs';
initializeApp({credential:applicationDefault(), projectId:process.env.GOOGLE_CLOUD_PROJECT});
const db=getFirestore();
const allowed=new Set((process.env.VOICE_ALLOWED_UIDS||'').split(',').filter(Boolean));
createServer(async(req,res)=>{
  res.setHeader('Cache-Control','no-store');
  if(req.method!=='POST' || req.url!=='/speak'){res.writeHead(404).end();return;}
  try {
    const key=process.env.ELEVENLABS_API_KEY;
    if(!key || !allowed.size){res.writeHead(503).end('Voice not activated');return;}
    const token=(req.headers.authorization||'').match(/^Bearer (.+)$/)?.[1];
    if(!token){res.writeHead(401).end();return;}
    let identity;
    try{identity=await getAuth().verifyIdToken(token,true);}catch{res.writeHead(401).end();return;}
    if(!allowed.has(identity.uid)){res.writeHead(403).end('Voice access not enabled');return;}
    let raw='';for await(const chunk of req){raw+=chunk;if(Buffer.byteLength(raw)>12000){res.writeHead(413).end();return;}}
    let data;try{data=validateSpeech(JSON.parse(raw));}catch{res.writeHead(400).end('Invalid advice');return;}
    const voice=data.language==='ta'?process.env.ELEVENLABS_TAMIL_VOICE_ID:process.env.ELEVENLABS_ENGLISH_VOICE_ID;
    if(!voice || !/^[a-zA-Z0-9_-]+$/.test(voice)){res.writeHead(503).end('Voice not selected');return;}
    const day=new Date().toISOString().slice(0,10);
    const u=db.doc(`voiceUsage/${day}-${identity.uid}`),g=db.doc(`voiceUsage/${day}-total`);
    const permitted=await db.runTransaction(async tx=>{
      const [ud,gd]=await Promise.all([tx.get(u),tx.get(g)]);
      const uc=ud.data()?.characters||0,gc=gd.data()?.characters||0;
      if(!withinBudget(uc,gc,data.text.length))return false;
      const expires=Timestamp.fromMillis(Date.now()+3*86400000);
      tx.set(u,{characters:uc+data.text.length,expires});tx.set(g,{characters:gc+data.text.length,expires});return true;
    });
    if(!permitted){res.writeHead(429).end('Daily voice allowance reached');return;}
    // Speech only. No diagnosis, instructions, or health conclusions are generated here.
    const speech=await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}?output_format=mp3_44100_128`,{
      method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},
      body:JSON.stringify({text:data.text,model_id:'eleven_v3',language_code:data.language,voice_settings:{stability:0.5,similarity_boost:0.75}}),signal:AbortSignal.timeout(15000)
    });
    if(!speech.ok){res.writeHead(502).end('Speech unavailable');return;}
    const audio=Buffer.from(await speech.arrayBuffer());
    if(audio.length>8000000)throw new Error('Audio too large');
    res.writeHead(200,{'Content-Type':'audio/mpeg'}).end(audio);
  }catch{if(!res.headersSent)res.writeHead(503);res.end('Voice unavailable');}
}).listen(Number(process.env.PORT||8080),'0.0.0.0');
