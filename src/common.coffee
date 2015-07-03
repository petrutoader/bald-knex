_ = require 'underscore'
async = require 'async'

module.exports = ->
  sendResponse = (res, err, data) ->
    response = {}
    response.data = data if data
    statusCode = 200

    response.error = err if err?

    headers = {'content-type': 'application/json; charset=utf-8'}
    res.set(headers).status(statusCode).end JSON.stringify response

  makeOperation = (action) ->
    operation = ->
      originalArgs = [].slice.call(arguments)
      # Arguments without the callback
      valueArgs = originalArgs.slice(0, -1)
      operationDone = originalArgs.slice(-1)[0]

      async.waterfall [
        # Runs the action to be run before executing the operation.
        # @param done {Function (err, valueArgs)} Move on to the next step.
        #   `valueArgs` represents the arguments to be passed on to the next
        #   operation.
        (done) ->
          if operation.before?
            # Pass the arguments received in `next` onto the function
            # that actually runs the operation.
            next = ->
              done(null, [].slice.call(arguments))
            operation.before.apply(null, valueArgs.concat(next))
          else
            done(null, valueArgs)

        # Runs the actual operation.
        # @param done {Function (err, dataArgs)} Move on to the next step.
        #   `dataArgs` represents the arguments returned after the execution
        #   of the operation (e.g. the actual data).
        # @param newValuesArgs {Object} What the operation needs to be
        #   called with.
        (newValueArgs, done) ->
          next = ->
            operationDone.apply(null, [].slice.call(arguments))
            done(null, [].slice.call(arguments))
          action.apply(null, newValueArgs.concat(next))

        # Runs things that need to be executed after the operation.
        # @param done {Function ()} Move on to the next step, which in
        #   this case is nothing.
        # @param dataArgs {Object} The data returned from the operation,
        #   to be used in `after`.
        (dataArgs, done) ->
          if operation.after?
            next = ->
              done()
            operation.after.apply(null, dataArgs.concat([valueArgs]).concat(next))
          else
            done()
      ]

  return {
    sendResponse
    makeOperation
  }
