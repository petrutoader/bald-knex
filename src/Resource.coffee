inflect = require 'inflect'
_ = require 'lodash'

Controller = require './Controller'
BaldError = require './Error'

class Bald
  constructor: ({app, knex}) ->
    throw new BaldError 'BaldInitializationError', 'Arguments invalid.' if !app?
    @app = app
    @knex = knex

  resource: ({model, primaryKey, endpoints, middleware}) ->
    throw new BaldError 'BaldResourceError', 'Invalid model.' if !model?

    primaryKey = primaryKey || 'id'
    endpoints = endpoints ||
      plural: '/api/' + inflect.pluralize model
      singular: '/api/' + inflect.singularize model + '/:pk'

    Controller
      app: @app
      knex: @knex
      model: model
      endpoints: endpoints
      primaryKey: primaryKey
      middleware: middleware

module.exports = Bald
