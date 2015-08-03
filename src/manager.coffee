async = require 'async'
_ = require 'underscore'

{makeOperation, handleError} = require('./common')
Association = require('./association')

module.exports = (model, eagerLoading) ->
  create = makeOperation (values, done) ->
    query = query || {}
    query.include = {all: true, nested: true} if eagerLoading

    async.waterfall [
      (done) ->
        model.create(values)
          .then (data) -> Association.attempt model, data, values, done
          .catch (err) -> handleError err, done
      (data, done) ->
        query.where = {}
        query.where[model.primaryKeyField] = data[model.primaryKeyField]
        model.find(query).then (data) -> done(null, data)
    ], (err, data) ->
      done(err, data)

  list = makeOperation (options, done) ->
    query = query || {}
    query.include = {all: true, nested: true} if eagerLoading

    if options.filter? && options.filterBy?
      query.where = {}
      query.where[options.filterBy] = options.filter

    if options.limit? && options.offset?
      query.limit = +options.limit
      query.offset = +options.offset

    if options.sort? && options.sortBy?
      query.order = options.sortBy + ' ' + options.sort

    model.findAll query
      .then (data) -> done null, data
      .catch (err) -> handleError err, done

  read = makeOperation (whereQuery, done) ->
    query = where: whereQuery
    query.include = all: true, nested: true if eagerLoading

    model.find query
      .then (data) -> done null, data
      .catch (err) -> handleError err, done

  update = makeOperation (query, values, done) ->
    query = where: query
    query.include = all: true, nested: true if eagerLoading

    updateValues = _.omit values, (value, key) ->
      return /\w+\.(set|add|remove)/.test(key)

    async.waterfall [
      (done) ->
        model.update(updateValues, query)
          .then (data) -> done null
          .catch (err) -> handleError err, done
      (done) ->
        model.find query
          .then (data) -> Association.attempt model, data, values, () -> done()
          .catch (err) -> handleError err, done
      (done) ->
        model.find query
          .then (data) -> done null, data
    ], (err, data) ->
      done err, data

  updateMultiple = makeOperation (values, done) ->
    updateValue = (value, done) ->
      async.waterfall [
        (done) ->
          model.update value, where: id: value.id
            .then (data) -> done null
            .catch (err) -> handleError err, done
        (done) ->
          query = where: id: value.id
          query.include = all: true, nested: true if eagerLoading

          model.find query
            .then (data) -> done null, value
      ], (err, data) ->
        done err, data
    async.map values, updateValue, done

  del = makeOperation (id, done) ->
    model.destroy where: id: id
      .then (data) -> done null, data
      .catch (err) -> handleError err, done

  return {
    create
    list
    read
    update
    updateMultiple
    del
  }
