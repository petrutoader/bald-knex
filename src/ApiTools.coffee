_ = require 'underscore'
BaldError = require './Error'

###
API error format:
{
  message: 'phy-invalid-something: Invalid something.'
  code: 'phy-invalid-something'
  extra: {
    anything: 'else we have from the error'
  }
}
###

string2phyCode = (str) ->
  ###
  * `str` [String]
  Returns [String] error code (e.g. 'phy-invalid-something')
  ###
  match = str.match(/phy-[a-zA-Z0-9-]+/)
  return match[0] if match
  return null

string2apiError = (str) ->
  ###
  * `str` [String]
  ###
  {
    message: str
    code: string2phyCode(str)
  }

jsError2apiError = (err) ->
  ###
  * `err` [Error]
  ###
  {
    message: err.message
    code: string2phyCode(err.message)
    extra: _.omit(err, 'message')
  }

other2apiError = (err) ->
  ###
  * `err`
  ###
  return {
    message: err?.message || 'Unknown error'
    code: string2phyCode(err?.message || 'Unknown error')
    extra: _.omit(err || {}, 'message')
  }

sendResponse = (res, err, data) ->
  throw new BaldError 'BaldInternalError', '`sendResponse()` Arguments invalid.' if !res?
  ###
  * `res`
  * `err` [Error/Array of Errors/String/Array of Strings]
  * `data` [Object]
  ###
  response = {}
  response.data = data || {}
  statusCode = 200

  if err
    if err.constructor == Array
      errors = err
    else
      errors = [err]

    errors = errors.map (error) ->
      if typeof error == 'string'
        return string2apiError(error)
      else if error instanceof Error
        return jsError2apiError(error)
      else
        return other2apiError(error)

    response.errors = errors
    statusCode = 400

  headers = {'content-type': 'application/json; charset=utf-8'}
  res.set(headers).status(statusCode).end(JSON.stringify(response))

module.exports = {
  sendResponse
  other2apiError
  jsError2apiError
  string2phyCode
  string2apiError
}
