inflection = require 'inflection'
manager = require './manager'
controller = require './controller'

class Bald
  constructor: ({app, sequelize}) ->
    throw new Error 'Arguments invalid.' if !app? || !sequelize?
    @app = app
    @sequelize = sequelize

  resource: ({model, endpoints, middleware}) ->
    throw new Error 'Invalid model.' if !model?

    endpoints = endpoints || {}
    if !endpoints.plural? && !endpoints.singular?
      plural = inflection.pluralize model.name

      endpoints = {
        plural: '/api/' + plural
        singular: '/api/' + plural + '/:id'
      }

    modelManager = manager model
    controller @app, endpoints, modelManager, middleware

    return modelManager

module.exports = Bald
