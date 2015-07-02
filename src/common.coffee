_ = require 'underscore'

module.exports = ->
  sendResponse = (res, err, data) ->
    response = {}
    response.data = data if data
    statusCode = 200

    response.error = err if err?

    headers = {'content-type': 'application/json; charset=utf-8'}
    res.set(headers).status(statusCode).end JSON.stringify response

  parseArgumentValues = (args) ->
    return _.values _.pick args, (value) ->
      return !_.isFunction value

  parseArgumentFunctions = (args) ->
    return _.values _.pick args, (value) ->
      return _.isFunction value

  makeOperation = (action) ->
    operation = ->
      oldArgs = arguments
      args = parseArgumentValues arguments

      args.push () ->
        values = oldArgs
        if arguments.length > 0
          values = parseArgumentValues arguments
          values.push parseArgumentFunctions(oldArgs)[0]
        action.apply null, values

      operation.before.apply null, args if operation.before?
      sequelizeObject = action.apply null, arguments if !operation.before?
      operation.after.call null, sequelizeObject if operation.after?

  return {
    sendResponse
    makeOperation
  }
