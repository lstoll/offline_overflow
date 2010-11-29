function(doc) {
  var ret = new Document();
  if(doc.kind == 'post') {
    // Child Post (answer)
    var scoreBoost = doc.Score / 20; // Arbitrary number. Think more later.
    if (doc.PostTypeId === 2 || doc.PostTypeId === '2') {
      ret.add(doc.Body, { boost: 1.25 + scoreBoost });
    }
    // Question
    else {
      ret.add(doc.Body, { boost: 2.0 + scoreBoost });
    }
    // Tags
    if (doc.Tags) {
      var tags = doc.Tags.replace('<', '').replace('>',' ');
      ret.add(tags, { boost: 3 });
    }
  }
  else if (doc.kind == 'comment') {
    ret.add(doc.Text, { boost: 1 });
  }
  return ret;
}

