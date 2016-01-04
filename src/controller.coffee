async = require 'async'

ApiTools = require './ApiTools'
BaldError = require './Error'

sendResponse = ApiTools.sendResponse

module.exports = ({app, knex, endpoints, model, primaryKey, middleware}) ->
  routes = [
    {
      name: 'list'
      method: 'get'
      url: endpoints.plural
      handler: (req, res) ->
        knex(model)
          .select()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
    {
      name: 'read'
      method: 'get'
      url: endpoints.singular
      handler: (req, res) ->
        where = {}
        where[primaryKey] = req.params.pk

        knex(model)
          .select()
          .where(where)
          .then(([data]) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
    {
      name: 'create'
      method: 'post'
      url: endpoints.plural
      handler: (req, res) ->
        async.waterfall [
          (done) ->
            knex(model)
              .insert(req.body)
              .then(([id]) -> done(null, id))
              .catch(done)
          (id, done) ->
            where = {}
            where[primaryKey] = id

            knex(model)
              .select()
              .where(where)
              .then(([data]) -> done(null, data))
              .catch(done)
        ], (err, data) ->
          sendResponse(res, err, data)
    }
    {
      name: 'update'
      method: 'put'
      url: endpoints.singular
      handler: (req, res) ->
        values = req.body
        values[primaryKey] = req.params.pk

        where = {}
        where[primaryKey] = req.params.pk

        async.waterfall [
          (done) ->
            knex(model)
              .where(where)
              .update(values)
              .then((data) -> done())
              .catch(done)
          (done) ->
            knex(model)
              .where(where)
              .select()
              .then(([data]) -> done(null, data))
              .catch(done)
        ], (err, data) ->
          sendResponse(res, err, data)
    }
    {
      name: 'delete'
      method: 'delete'
      url: endpoints.singular
      handler: (req, res) ->
        where = {}
        where[primaryKey] = req.params.pk

        knex(model)
          .where(where)
          .del()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
  ]

  routes.map (route) ->
    throw new BaldError 'BaldControllerError', 'Invalid middleware array provided.' if middleware? && typeof middleware != 'object'
    routeMiddleware = middleware[route.name] || [] if middleware?
    routeMiddleware = [] if !middleware?

    app[route.method](route.url, routeMiddleware, route.handler)
