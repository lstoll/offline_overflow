/**
 * We want this to be queried for any item's ID, and return the parent questions's ID.
 */
function(doc) {
  if (doc.kind === 'post') {
    if (doc.PostTypeId === 2 || doc.PostTypeId === '2') {
      emit(doc._id, doc.ParentId);
    }
    else {
      emit(doc._id, doc._id);
    }
  }
  else if (doc.kind === 'comment') {
    if (doc.ParentId) {
      emit(doc._id, doc.ParentId);
    }
    else {
      emit(doc._id, doc.PostId);
    }
  }
}
