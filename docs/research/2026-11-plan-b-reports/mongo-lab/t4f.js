const d=db.getSiblingDB("lab"); let ok=0, err=0;
for(let i=0;i<10;i++){
  try { d.trades2.updateOne({customerId:123, count:{$lt:10}}, {$push:{history:{t:new Date()}}, $inc:{count:1}, $setOnInsert:{_id:new ObjectId(), first:new Date()}}, {upsert:true}); ok++; }
  catch(e){ err++; print(e.code+" "+e.message.slice(0,80)); }
}
print(ok+" "+err);
