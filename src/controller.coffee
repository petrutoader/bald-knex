sendResponse = (res, err, data) ->
  response = {}
  response.data = data if data
  statusCode = 200

  response.error = err if err?

  headers = {'content-type': 'application/json; charset=utf-8'}
  res.set(headers).status(statusCode).end JSON.stringify response

module.exports = (app, endpoint, manager) ->
  routes = [
    {
      method: 'get'
      url: endpoint.plural
      handler: (req, res) ->
        manager.list (err, data) ->
          sendResponse res, err, data
    }
    {
      method: 'get'
      url: endpoint.singular
      handler: (req, res) ->
        manager.read req.params.id, (err, data) ->
          sendResponse res, err, data
    }
    {
      method: 'post'
      url: endpoint.plural
      handler: (req, res) ->
        manager.create req.body, (err, data) ->
          sendResponse res, err, data
    }
    {
      method: 'put'
      url: endpoint.singular
      handler: (req, res) ->
        manager.updateOne req.params.id, req.body, (err, data) ->
          sendResponse res, err, data
    }
    {
      method: 'put'
      url: endpoint.plural
      handler: (req, res) ->
        values = JSON.parse req.body.values
        manager.updateMultiple values, (err, data) ->
          sendResponse res, err, data
    }
    {
      method: 'delete'
      url: endpoint.singular
      handler: (req, res) ->
        manager.del req.params.id, (err, data) ->
          sendResponse res, err, data
    }
  ]

  routes.map (route) ->
    # TODO: Support middleware (isAdmin etc.)
    app[route.method](route.url, route.handler)
