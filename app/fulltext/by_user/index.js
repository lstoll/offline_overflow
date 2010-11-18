function(doc) {
  if(doc.kind == 'user') {
    var ret = new Document();
    ret.add(doc.AboutMe);
    return ret;
  }
}
