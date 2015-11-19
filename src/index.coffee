inflect = require 'inflect'
manager = require './manager'
controller = require './controller'
BaldError = require './error'

class Bald
  constructor: ({app}) ->
    throw new BaldError 'BaldInitializationError', 'Arguments invalid.' if !app?
    @app = app

  resource: ({model, endpoints, middleware, include, hasApi}) ->
    hasApi = true if !hasApi?
    throw new BaldError 'BaldResourceError', 'Invalid model.' if !model?

    endpoints = endpoints || {}
    if !endpoints.plural? && !endpoints.singular?

      endpoints =
        plural: '/api/' + inflect.pluralize model.name
        singular: '/api/' + inflect.singularize model.name + '/:id'

    modelManager = manager model, include
    modelManager.model = model

    controller @app, endpoints, modelManager, middleware if hasApi

    return modelManager

module.exports = Bald
