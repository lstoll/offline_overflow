function(doc) {
  if(doc.kind == 'post') {
    var ret = new Document();
    ret.add(doc.Body, { boost: 2.0 });
    for(i in doc.answers) {
      ret.add(doc.answers[i].Body, { boost: 1.0 });
    }
    return ret;
  }
}

