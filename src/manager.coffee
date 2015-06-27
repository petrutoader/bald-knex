_ = require 'underscore'
async = require 'async'

parseArgumentValues = (args) ->
  return _.values _.pick args, (value) ->
    return !_.isFunction value

parseArgumentFunctions = (args) ->
  return _.values _.pick args, (value) ->
    return _.isFunction value

makeOperation = (action) ->
  operation = ->
    oldArgs = arguments
    args = parseArgumentValues arguments

    args.push () ->
      values = oldArgs
      if arguments.length > 0
        values = parseArgumentValues arguments
        values.push parseArgumentFunctions(oldArgs)[0]
      action.apply null, values

    operation.before.apply null, args if operation.before?
    action.apply null, arguments if !operation.before?
    operation.after.apply null, args if operation.after?
  return operation

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
