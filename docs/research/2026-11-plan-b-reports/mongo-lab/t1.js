const d=db.getSiblingDB("lab"); d.movies.drop();
const L=["US","FR","IT","UK","DE","JP","CN","KR","BR","IN"]; const base=new Date("2020-01-01");
let b=[]; for(let i=0;i<100000;i++){ const r=[]; for(let k=0;k<5;k++){ r.push({location:L[(i+k*3)%10], date:new Date(base.getTime()+((i*7+k*13)%1500)*86400000)}); } b.push({_id:i,title:"m"+i,releases:r}); if(b.length==5000){d.movies.insertMany(b);b=[];} }
d.movies.createIndex({releases:1},{name:"A"}); d.movies.createIndex({"releases.location":1,"releases.date":1},{name:"B"});
const q={releases:{$elemMatch:{location:"US",date:{$gt:new Date("2023-06-01")}}}};
function ex(h){ const e=d.movies.find(q).hint(h).explain("executionStats"); const s=e.executionStats; let st=e.queryPlanner.winningPlan; while(st.inputStage) st=st.inputStage; return {h, n:s.nReturned, keys:s.totalKeysExamined, docs:s.totalDocsExamined, ms:s.executionTimeMillis, bounds:JSON.stringify(st.indexBounds).slice(0,200)}; }
printjson(ex("A")); printjson(ex("B"));
const e=d.movies.find(q).explain(); let w=e.queryPlanner.winningPlan; while(w.inputStage) w=w.inputStage; print("planner picks:", w.indexName||w.stage);
// whole-subdoc equality
const q2={releases:{location:"US",date:new Date("2023-06-02")}};
const e2=d.movies.find(q2).hint("A").explain("executionStats"); print("A exact subdoc eq: n="+e2.executionStats.nReturned+" keys="+e2.executionStats.totalKeysExamined);
const q3={releases:{date:new Date("2023-06-02"),location:"US"}}; print("field order swapped n="+d.movies.countDocuments(q3)+" vs "+d.movies.countDocuments(q2));
