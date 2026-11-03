const d=db.getSiblingDB("lab"); let ok=0, dup=0, other=0;
for(let i=0;i<10;i++){
  try { d.trades.updateOne({_id:/^123_/, count:{$lt:10}}, {$push:{history:{t:new Date(), w:typeof W=="undefined"?0:W}}, $inc:{count:1}, $setOnInsert:{_id:"123_"+Math.floor(Date.now()/1000), customerId:123}}, {upsert:true}); ok++; }
  catch(e){ if(e.code==11000) dup++; else {other++; print(e.message);} }
}
print(ok+" "+dup+" "+other);
