const d=db.getSiblingDB("lab"); d.sub.drop(); d.msg6.drop();
let b=[]; for(let i=0;i<5000;i++) b.push({rid:"big",uid:"u"+i,unread:0,ls:new Date(0)}); d.sub.insertMany(b);
d.sub.createIndex({rid:1,uid:1},{unique:true}); d.msg6.createIndex({rid:1,ts:1,_id:1});
const oplog=db.getSiblingDB("local").oplog.rs; const o0=oplog.countDocuments({ns:"lab.sub"});
const N=200; let t=Date.now();
for(let i=0;i<N;i++){ const ts=new Date(); d.msg6.insertOne({rid:"big",ts,u:"u"+(i%5000)}); d.sub.updateMany({rid:"big",uid:{$ne:"u"+(i%5000)}},{$inc:{unread:1}}); }
const per=(Date.now()-t)/N; const o1=oplog.countDocuments({ns:"lab.sub"});
print("T6 write-time: per message ms="+per.toFixed(1), "oplog entries per message="+((o1-o0)/N).toFixed(0));
// read-time alternative
t=Date.now(); for(let i=0;i<200;i++){ d.msg6.countDocuments({rid:"big",ts:{$gt:new Date(0)}},{limit:100}); } print("T6 read-time countDocuments(limit 100) ms per call="+((Date.now()-t)/200).toFixed(2));
t=Date.now(); for(let i=0;i<N;i++){ d.msg6.insertOne({rid:"big",ts:new Date(),u:"x"}); } print("T6 baseline insert only ms="+((Date.now()-t)/N).toFixed(2));
const st=db.getSiblingDB("local").oplog.rs.stats(); print("oplog size MB="+(st.size/1048576).toFixed(1));
