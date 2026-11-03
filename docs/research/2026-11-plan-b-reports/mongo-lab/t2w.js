const d=db.getSiblingDB("lab"); let ok=0, okn=0;
for(let i=0;i<5;i++){
  const r=d.stock.updateOne({_id:"c", available:{$gte:1}},{$inc:{available:-1, reserved:1}}); if(r.matchedCount==1) ok++;
  // naive: read-then-write
  const s=d.stock.findOne({_id:"n"}); if(s.available>=1){ d.stock.updateOne({_id:"n"},{$inc:{available:-1, reserved:1}}); okn++; }
}
print(ok+" "+okn);
