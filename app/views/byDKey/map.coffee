( doc ) ->

  return if doc.collection is "result"

  if doc.curriculumId
    id = doc.curriculumId
    return if doc.collection is "klass" # don't move classes
  else if doc.collection is "workflow"
    id = doc._id
  else if doc.collection is "feedback"
    idSuffix = "-feedback"
    id = doc._id.substring(0, doc._id.length - idSuffix.length)

  else
    id = doc.assessmentId

  emit id.substr(-5,5), null
