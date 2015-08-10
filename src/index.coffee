inflect = require 'inflect'
manager = require './manager'
controller = require './controller'
BaldError = require './error'

class Bald
  constructor: ({app}) ->
    throw new BaldError 'BaldInitializationError', 'Arguments invalid.' if !app?
    @app = app

  resource: ({model, endpoints, middleware, include}) ->
    throw new BaldError 'BaldResourceError', 'Invalid model.' if !model?
    throw new BaldError 'BaldResourceError', 'Invalid endpoints.' if endpoints? && typeof endpoints != 'object'

    endpoints = endpoints || {}
    if !endpoints.plural? && !endpoints.singular?

      endpoints =
        plural: '/api/' + inflect.pluralize model.name
        singular: '/api/' + inflect.singularize model.name + '/:id'

    modelManager = manager model, include
    controller @app, endpoints, modelManager, middleware

    return modelManager

module.exports = Bald
