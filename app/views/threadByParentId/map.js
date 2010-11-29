/**
 * We want this to be queried for a given question ID, and be able to find the thread
 */
function(doc) {
  //emit([doc.room, new Date(doc.posted_at)], doc);
  if (doc.kind === 'post') {
    // Check type. If not 2, just emit the ID with two nulls.
    //emit(doc.Id, doc._id);
    if (doc.PostTypeId === 2 || doc.PostTypeId === '2') {
      emit([doc.ParentId, 1, doc._id, doc.CreationDate], doc._id);
    }
    else {
      // just a parent doc.
      emit([doc._id], doc._id);
    }
  }
  else if (doc.kind === 'comment') {
    if (doc.ParentId) {
      // Post will be before comment anyway, as it's creation date will always be less.
      emit([doc.ParentId, 1, doc.PostId, doc.CreationDate], doc._id);
    }
    else {
      // the 0 here ensures it comes up before the parent post's comments
      emit([doc.PostId, 0, doc.PostId, doc.CreationDate], doc._id);
    }
  }
}
