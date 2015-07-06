{sendResponse} = require('./common')()

module.exports = (app, endpoint, manager, middleware) ->
  routes = [
    {
      name: 'list'
      method: 'get'
      url: endpoint.plural
      handler: (req, res) ->
        manager.list (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'read'
      method: 'get'
      url: endpoint.singular
      handler: (req, res) ->
        manager.read id: req.params.id, (err, data) ->
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
        manager.update req.params.id, req.body, (err, data) ->
          sendResponse res, err, data
    }
    {
      name: 'updateMultiple'
      method: 'put'
      url: endpoint.plural
      handler: (req, res) ->
        values = JSON.parse req.body.values
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
    routeMiddleware = middleware[route.name] || [] if middleware?
    routeMiddleware = [] if !middleware?

    app[route.method](route.url, routeMiddleware, route.handler)
