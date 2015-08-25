{sendResponse} = require './apiTools'
{handleError} = require './common'

BaldError = require './error'

module.exports = (app, endpoint, manager, middleware) ->
  routes = [
    {
      name: 'list'
      method: 'get'
      url: endpoint.plural
      handler: (req, res) ->
        query = {}
        query.where = req.query
        query.include = JSON.parse req.query.include if req.query.include?
        delete query.where.include

        manager.list query, (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'read'
      method: 'get'
      url: endpoint.singular
      handler: (req, res) ->
        query = {}
        query.where = id: req.params.id
        query.include = JSON.parse req.query.include if req.query.include?

        manager.read query, (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'create'
      method: 'post'
      url: endpoint.plural
      handler: (req, res) ->
        manager.create req.body, (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'update'
      method: 'put'
      url: endpoint.singular
      handler: (req, res) ->
        manager.update id: req.params.id, req.body, (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'updateMultiple'
      method: 'put'
      url: endpoint.plural
      handler: (req, res, next) ->
        try
          values = JSON.parse req.body.values
        catch
          err = new Error 'Invalid JSON data sent to updateMultiple route.'
          return sendResponse res, err

        manager.updateMultiple values, (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'delete'
      method: 'delete'
      url: endpoint.singular
      handler: (req, res) ->
        manager.del req.params.id, (err, data) ->
          sendResponse res, err, data
    }
  ]

  routes.map (route) ->
    throw new BaldError 'BaldControllerError', 'Invalid middleware array provided.' if middleware? && typeof middleware != 'object'
    routeMiddleware = middleware[route.name] || [] if middleware?
    routeMiddleware = [] if !middleware?

    app[route.method](route.url, routeMiddleware, route.handler)
