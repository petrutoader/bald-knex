{sendResponse} = require('./common')()
_ = require('underscore')

module.exports = (app, endpoint, manager, middleware) ->
  pageResults = (data, count, page) ->
    return _.first(_.rest(data, count * (page - 1)), count)

  sortResults = (data, sortBy, sort) ->
    sortBy == 'id' if !sortBy?
    return _.sortBy(data, sortBy).reverse() if sort == 'desc'
    return _.sortBy(data, sortBy)

  filterResults = (data, filterBy, filter) ->
    filter = +filter if data.length > 0 && typeof data[0][filterBy] == 'number'
    return _.where(data, _.object([filterBy], [filter]))

  routes = [
    {
      name: 'list'
      method: 'get'
      url: endpoint.plural
      handler: (req, res) ->
        manager.list (err, data) ->
          if req.query.filterBy? && req.query.filter?
            data = filterResults(data, req.query.filterBy, req.query.filter)
          if req.query.sort?
            data = sortResults(data, req.query.sortBy, req.query.sort)
          if req.query.count? && req.query.page?
            data = pageResults(data, req.query.count, req.query.page)
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
