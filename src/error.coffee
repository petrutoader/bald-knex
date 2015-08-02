class BaldError
  constructor: (@name, @message) ->
    err = new Error @message
    err.name = @name
    return err

module.exports = BaldError
