PERSONAS = {
"Lena (Studentin, Schulden)": r"""ctx=>{const {mkGoal,mkHabit,rnd}=ctx;
 const debt=mkGoal({title:'Schuldenfrei',due:ymd(addD(new Date(),720)),metric:{type:'number',start:-12000,current:-12000,target:0,unit:'€'}});
 const ba=mkGoal({title:'Bachelor bestehen',due:ymd(addD(new Date(),540)),metric:{type:'milestones'},milestones:[1,2,3,4,5,6].map(n=>({id:uid(),title:'Modul '+n,done:false}))});
 mkHabit({title:'Lernen',days:[1,2,3,4,5]}); mkHabit({title:'Laufen',days:[2,4]});
 return {
  day(i,dt){const we=dt.getDay()%6===0;const tasks=[],work=[];
   if(!we){const a={title:'Vorlesung nacharbeiten',goal:ba};tasks.push(a);work.push({task:a,h:15,dur:45+Math.floor(rnd()*75),done:rnd()<.7,forget:(i%90===45)?3:0});}
   if(rnd()<.4)tasks.push({title:'Bewerbung schreiben'});
   if(rnd()<.2)tasks.push({title:'Idee: Nebenjob suchen',inbox:true});
   if(i===0){const r={title:'Rate überweisen',goal:debt,repeat:'monatlich'};tasks.push(r);}
   const due=S.tasks.find(t=>t.title==='Rate überweisen'&&!t.done&&t.date===ymd(dt));if(due)work.push({task:{ref:due},h:8,dur:10});
   return {tasks,work};},
  habitP:(h)=>h.title==='Lernen'?.6:.5,
  evening(i,dt){if(dt.getDate()===1){debt.metric.current=Math.min(0,debt.metric.current+300+Math.round(rnd()*200));}
   if(i%90===89){const m=ba.milestones.find(x=>!x.done);if(m)m.done=true;}}
 }}""",
"Markus (Angestellter, ETF-Depot)": r"""ctx=>{const {mkGoal,mkHabit,rnd}=ctx;
 const etf=mkGoal({title:'ETF-Depot 100.000 €',due:ymd(addD(new Date(),900)),metric:{type:'number',start:25000,current:25000,target:100000,unit:'€'}});
 const hm=mkGoal({title:'Halbmarathon',due:ymd(addD(new Date(),300)),metric:{type:'milestones'},milestones:[{id:uid(),title:'10 km',done:false},{id:uid(),title:'15 km',done:false},{id:uid(),title:'Lauf',done:false}]});
 mkHabit({title:'Lesen',days:[1,2,3,4,5,6,7]}); mkHabit({title:'Sport',days:[1,3,5],goalId:hm.id});
 return {
  linkEvents:e=>/Fitness/.test(e.title)?hm:null,
  day(i,dt){const tasks=[],work=[];const we=dt.getDay()%6===0;
   if(!we){const a={title:'Weiterbildung Finanzen',goal:etf,time:'19:00'};tasks.push(a);work.push({task:a,h:19,dur:60,pauseAfter:25});}
   if(i===5){tasks.push({title:'Depot prüfen',goal:etf,repeat:'wöchentlich'});}
   const dp=S.tasks.find(t=>t.title==='Depot prüfen'&&!t.done&&t.date<=ymd(dt));if(dp&&rnd()<.8)work.push({task:{ref:dp},h:10,dur:15});
   if(rnd()<.5){const b={title:'Einkauf'};tasks.push(b);work.push({task:b,h:17,m:30,dur:20});}
   return {tasks,work};},
  habitP:(h)=>h.title==='Lesen'?1:.85,
  evening(i,dt){if(dt.getDate()===1){etf.metric.current=Math.round(etf.metric.current*(0.95+rnd()*0.1)+800);}
   if(i===120)hm.milestones[0].done=true; if(i===250)hm.milestones[1].done=true;}
 }}""",
"Aylin (Selbststaendig, Krypto+Firma)": r"""ctx=>{const {mkGoal,mkHabit,rnd}=ctx;
 const mio=mkGoal({title:'1 Mio. mit Firma & Krypto',due:ymd(addD(new Date(),2000)),metric:{type:'number',start:50000,current:50000,target:1000000,unit:'€'}});
 const app=mkGoal({title:'App launchen',due:ymd(addD(new Date(),120)),metric:{type:'milestones'},milestones:[{id:uid(),title:'Beta',done:false},{id:uid(),title:'Launch',done:false}]});
 mkHabit({title:'Meditation',days:[1,2,3,4,5,6,7]}); mkHabit({title:'Kein Alkohol',days:[1,2,3,4,5,6,7]});
 return {
  day(i,dt){const tasks=[],work=[];
   const a={title:'Kundenprojekt',goal:mio,time:'14:00'};tasks.push(a);work.push({task:a,h:14,dur:90+Math.floor(rnd()*120)});
   if(rnd()<.3)tasks.push({title:'Steuer-Belege',inbox:true});
   return {tasks,work,night:rnd()<.6?{title:'Nachtschicht am Produkt',goal:app}:null};},
  habitP:(h)=>h.title==='Meditation'?.4:.7,
  evening(i,dt){if(dt.getDate()===1){mio.metric.current=Math.max(0,Math.round(mio.metric.current*(0.7+rnd()*0.8)));}
   if(i===100)app.milestones[0].done=true;}
 }}""",
"Jonas (Schichtarbeit, Immobilie + Pilot)": r"""ctx=>{const {mkGoal,mkHabit,rnd}=ctx;
 const ek=mkGoal({title:'Eigenkapital Wohnung',due:ymd(addD(new Date(),1400)),metric:{type:'number',start:0,current:0,target:80000,unit:'€'}});
 const lapl=mkGoal({title:'LAPL(A) bestehen',due:ymd(addD(new Date(),1460)),metric:{type:'milestones'},milestones:[1,2,3,4,5,6,7,8,9].map(n=>({id:uid(),title:'Fach '+n,done:false}))});
 const fs=mkGoal({title:'Führerschein',due:ymd(addD(new Date(),330)),metric:{type:'milestones'},milestones:[{id:uid(),title:'Theorie',done:false},{id:uid(),title:'Praxis',done:false}]});
 const h1=mkHabit({title:'LAPL lernen',days:[1,2,3],goalId:lapl.id}); mkHabit({title:'Dehnen',days:[1,2,3,4,5,6,7]});
 return {
  linkEvents:e=>/Fahrstunde/.test(e.title)?fs:/Schnupperflug/.test(e.title)?lapl:null,
  day(i,dt){const tasks=[],work=[];const early=Math.floor(i/7)%2===0;
   const a={title:'LAPL Fach lernen',goal:lapl,time:early?'16:00':'09:00'};tasks.push(a);work.push({task:a,h:early?16:9,dur:50});
   if(rnd()<.3)tasks.push({title:'Behördengang'});
   return {tasks,work};},
  habitP:(h)=>.75,
  evening(i,dt,T){S.reflections['tag:'+T]={gut:'x',saved:Date.now()};
   if(dt.getDate()===15&&rnd()<.5)ek.metric.current+=Math.round(5000+rnd()*15000);
   if(i%80===79){const m=lapl.milestones.find(x=>!x.done);if(m)m.done=true;}
   if(i===180)h1.days=[4,5,6,7];
   if(i===300){fs.status='erreicht';}
   if(i===310){mkGoal({title:'Nachtflug-Berechtigung',due:ymd(addD(new Date(),-20)),metric:{type:'milestones'},milestones:[]});}}
 }}""",
}
