async = require 'async'
{makeOperation} = require('./common')()

module.exports = (model) ->
  create = makeOperation (values, done) ->
    model.create values
      .then (data) -> done null, data
      .catch done

  list = makeOperation (done) ->
    model.findAll {}
      .then (data) -> done null, data
      .catch done

  read = makeOperation (id, done) ->
    model.find where: id: id
      .then (data) -> done null, data
      .catch done

  update = makeOperation (id, values, done) ->
    async.waterfall [
      (done) ->
        model.update values, where: id: id
          .then (data) -> done null
          .catch done
      (done) ->
        model.find where: id: id
          .then (data) -> done null, data
          .catch done
    ], (err, data) ->
      done err, data

  updateMultiple = makeOperation (values, done) ->
    updateValue = (value, done) ->
      async.waterfall [
        (done) ->
          model.update value, where: id: value.id
            .then (data) -> done null
            .catch done
        (done) ->
          model.find where: id: value.id
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
