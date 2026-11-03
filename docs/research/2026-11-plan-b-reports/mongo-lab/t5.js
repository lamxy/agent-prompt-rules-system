const d=db.getSiblingDB("lab"); d.msg.drop();
const t0=new Date("2026-01-01").getTime(); let b=[];
for(let i=0;i<300000;i++){ b.push({rid:"r"+(i%1000), ts:new Date(t0+Math.floor(i/1000)*1000*(i%3==0?1:1)), u:"u"+(i%50), msg:"x"}); if(b.length==10000){d.msg.insertMany(b);b=[];} }
// make ts duplicates within a room: every 2 consecutive messages in room share ts
d.msg.updateMany({}, [{$set:{ts:{$dateTrunc:{date:"$ts",unit:"second",binSize:2}}}}]);
d.msg.createIndex({rid:1,ts:1},{name:"rt"}); d.msg.createIndex({rid:1,ts:1,_id:1},{name:"rti"});
const R="r7";
for (const h of ["rt","rti"]) { const e=d.msg.find({rid:R}).sort({ts:-1,_id:-1}).limit(50).hint(h).explain("executionStats"); const st=JSON.stringify(e.queryPlanner.winningPlan); print("T5", h, "sort(ts,_id) keys="+e.executionStats.totalKeysExamined, "docs="+e.executionStats.totalDocsExamined, "SORTstage="+st.includes('"SORT"')); }
const all=d.msg.find({rid:R}).sort({ts:-1,_id:-1}).toArray().map(x=>String(x._id));
// paginate ts-only cursor
function pageTs(){ let out=[], last=null; while(true){ const q=last?{rid:R,ts:{$lt:last}}:{rid:R}; const p=d.msg.find(q).sort({ts:-1,_id:-1}).limit(50).toArray(); if(!p.length) break; out.push(...p.map(x=>String(x._id))); last=p[p.length-1].ts; } return out; }
function pageTsId(){ let out=[], lt=null, li=null; while(true){ const q=lt?{rid:R,$or:[{ts:{$lt:lt}},{ts:lt,_id:{$lt:li}}]}:{rid:R}; const p=d.msg.find(q).sort({ts:-1,_id:-1}).limit(50).toArray(); if(!p.length) break; out.push(...p.map(x=>String(x._id))); lt=p[p.length-1].ts; li=p[p.length-1]._id; } return out; }
const a=pageTs(), c=pageTsId(); print("T5 total="+all.length, "ts-only cursor got="+a.length, "ts+_id cursor got="+c.length, "match="+(JSON.stringify(c)==JSON.stringify(all)));
