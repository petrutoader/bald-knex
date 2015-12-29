inflect = require 'inflect'
_ = require 'lodash'
controller = require './controller'
BaldError = require './error'

class Bald
  constructor: ({app, bookshelf}) ->
    throw new BaldError 'BaldInitializationError', 'Arguments invalid.' if !app?
    @app = app
    @bookshelf = bookshelf

  resource: ({model, endpoints, middleware}) ->
    throw new BaldError 'BaldResourceError', 'Invalid model.' if !model?

    endpoints = endpoints || {}


    if !endpoints.plural? && !endpoints.singular?
      name = model.prototype.tableName

      endpoints =
        plural: '/api/' + inflect.pluralize name
        singular: '/api/' + inflect.singularize name + '/:id'

    controller @app, endpoints, model, middleware

module.exports = Bald
