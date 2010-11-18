function(doc) {
  //emit([doc.room, new Date(doc.posted_at)], doc);
  if (doc.kind === 'post') {
    for (i in doc.answers) {
      var answer = doc.answers[i];
      emit(answer.Id, doc._id);
    }
    emit(doc.Id, doc._id);
  }
}
