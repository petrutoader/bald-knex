async = require 'async'
{makeOperation} = require('./common')()

module.exports = (model, eagerLoading) ->
  create = makeOperation (values, done) ->
    model.create values
      .then (data) -> done null, data
      .catch done

  list = makeOperation (done) ->
    query = {}
    query.include = {all: true, nested: true} if eagerLoading?

    model.findAll query
      .then (data) -> done null, data
      .catch done

  read = makeOperation (whereQuery, done) ->
    query = where: whereQuery
    query.include = all: true, nested: true if eagerLoading?

    model.find query
      .then (data) -> done null, data
      .catch done

  update = makeOperation (id, values, done) ->
    query = where: id: id
    query.include = all: true, nested: true if eagerLoading?

    async.waterfall [
      (done) ->
        model.update values, query
          .then (data) -> done null
          .catch done
      (done) ->
        model.find query
          .then (data) -> done null, data
          .catch done
    ], (err, data) ->
      done err, data

  updateMultiple = makeOperation (values, done) ->
    query = where: id: values.id
    query.include = all: true, nested: true if eagerLoading?

    updateValue = (value, done) ->
      async.waterfall [
        (done) ->
          model.update value, query
            .then (data) -> done null
            .catch done
        (done) ->
          model.find query
            .then (data) -> done null, value
            .catch done
      ], (err, data) ->
        done null, data
    async.map values, updateValue, done

  del = makeOperation (id, done) ->
    model.destroy where: id: id
      .then (data) -> done null, data
      .catch done

  return {
    create
    list
    read
    update
    updateMultiple
    del
  }
