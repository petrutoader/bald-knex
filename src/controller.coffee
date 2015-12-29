{sendResponse} = require './apiTools'
{handleError} = require './common'

BaldError = require './error'

module.exports = (app, endpoint, model, middleware) ->
  routes = [
    {
      name: 'list'
      method: 'get'
      url: endpoint.plural
      handler: (req, res) ->
        model
          .fetchAll()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
    {
      name: 'read'
      method: 'get'
      url: endpoint.singular
      handler: (req, res) ->
        model
          .where(id: req.params.id)
          .fetch()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
    {
      name: 'create'
      method: 'post'
      url: endpoint.plural
      handler: (req, res) ->
        model
          .forge(req.body)
          .save()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
    {
      name: 'update'
      method: 'put'
      url: endpoint.singular
      handler: (req, res) ->
        values = req.body
        values.id = req.params.id

        model
          .forge(values)
          .save()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
    {
      name: 'delete'
      method: 'delete'
      url: endpoint.singular
      handler: (req, res) ->
        model
          .forge(id: req.params.id)
          .destroy()
          .then((data) -> sendResponse(res, null, data))
          .catch((err) -> sendResponse(res, err))
    }
  ]

  routes.map (route) ->
    throw new BaldError 'BaldControllerError', 'Invalid middleware array provided.' if middleware? && typeof middleware != 'object'
    routeMiddleware = middleware[route.name] || [] if middleware?
    routeMiddleware = [] if !middleware?

    app[route.method](route.url, routeMiddleware, route.handler)
