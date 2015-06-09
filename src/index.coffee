inflection = require 'inflection'
manager = require './manager'
controller = require './controller'

class Bald
  constructor: ({app, sequelize}) ->
    throw new Error 'Arguments invalid.' if !app? || !sequelize?
    @app = app
    @sequelize = sequelize

  resource: ({model, endpoints}) ->
    throw new Error 'Invalid model.' if !model?

    endpoints = endpoints || []
    if endpoints.length == 0
      plural = inflection.pluralize model.name

      endpoint = {
        plural: '/api/' + plural
        singular: '/api/' + plural + '/:id'
      }

    manager = manager(model)
    controller(@app, endpoint, manager)

    return manager

module.exports = Bald
