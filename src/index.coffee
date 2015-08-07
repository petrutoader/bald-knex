inflect = require 'inflect'
manager = require './manager'
controller = require './controller'

class Bald
  constructor: ({app, sequelize}) ->
    throw new Error 'Arguments invalid.' if !app? || !sequelize?
    @app = app
    @sequelize = sequelize

  resource: ({model, endpoints, middleware, include}) ->
    throw new Error 'Invalid model.' if !model?
    throw new Error 'Invalid endpoints.' if endpoints? && typeof endpoints != 'object'

    endpoints = endpoints || {}
    if !endpoints.plural? && !endpoints.singular?

      endpoints =
        plural: '/api/' + inflect.pluralize model.name
        singular: '/api/' + inflect.singularize model.name + '/:id'

    modelManager = manager model, include
    controller @app, endpoints, modelManager, middleware

    return modelManager

module.exports = Bald
