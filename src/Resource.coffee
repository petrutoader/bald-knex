inflect = require 'inflect'
_ = require 'lodash'

Controller = require './Controller'
BaldError = require './Error'

class Bald
  constructor: ({app, knex}) ->
    throw new BaldError 'BaldInitializationError', 'Arguments invalid.' if !app?
    @app = app
    @knex = knex

  resource: ({model, endpoints, middleware}) ->
    throw new BaldError 'BaldResourceError', 'Invalid model.' if !model?

    endpoints = endpoints || {}
    if !endpoints.plural? && !endpoints.singular?
      endpoints =
        plural: '/api/' + inflect.pluralize model
        singular: '/api/' + inflect.singularize model + '/:id'

    Controller
      app: @app
      knex: @knex
      model: model
      endpoints: endpoints
      middleware: middleware

module.exports = Bald
