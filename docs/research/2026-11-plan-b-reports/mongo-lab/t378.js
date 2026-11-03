const d=db.getSiblingDB("lab");
// T3
d.prices.drop(); d.prices.insertMany([{_id:"30671_store23",p:1},{_id:"30671_store1",p:2},{_id:"306710_store1",p:3},{_id:"3067_store1",p:4}]);
for (const re of [/^30671/, /^30671_/]) { const e=d.prices.find({_id:re}).explain("executionStats"); let w=e.queryPlanner.winningPlan; while(w.inputStage) w=w.inputStage; print("T3", re, "n="+e.executionStats.nReturned, w.stage, "keys="+e.executionStats.totalKeysExamined, d.prices.find({_id:re}).toArray().map(x=>x._id).join(",")); }
// T7
d.products.drop(); d.products.insertOne({_id:1,recentReviews:[]});
for(let i=1;i<=8;i++) d.products.updateOne({_id:1},{$push:{recentReviews:{$each:[{rid:i,at:new Date(2026,0,i)}],$sort:{at:-1},$slice:5}}});
print("T7", JSON.stringify(d.products.findOne({_id:1}).recentReviews.map(r=>r.rid)));
// T8
db.adminCommand({setParameter:1, ttlMonitorSleepSecs:5});
d.carts.drop(); d.inv.drop();
d.inv.insertOne({_id:"sku1",available:8,reserved:2});
d.carts.createIndex({expireAt:1},{expireAfterSeconds:0});
d.carts.insertOne({_id:"u1",items:[{sku:"sku1",q:2}],expireAt:new Date(Date.now()+2000)});
sleep(15000);
print("T8 cart exists="+(d.carts.countDocuments({_id:"u1"})), "inv="+JSON.stringify(d.inv.findOne()));
