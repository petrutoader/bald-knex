// Generated by CoffeeScript 1.10.0
(function() {
  var BaldError, _, jsError2apiError, other2apiError, sendResponse, string2apiError, string2phyCode;

  _ = require('underscore');

  BaldError = require('./Error');


  /*
  API error format:
  {
    message: 'phy-invalid-something: Invalid something.'
    code: 'phy-invalid-something'
    extra: {
      anything: 'else we have from the error'
    }
  }
   */

  string2phyCode = function(str) {

    /*
    * `str` [String]
    Returns [String] error code (e.g. 'phy-invalid-something')
     */
    var match;
    match = str.match(/phy-[a-zA-Z0-9-]+/);
    if (match) {
      return match[0];
    }
    return null;
  };

  string2apiError = function(str) {

    /*
    * `str` [String]
     */
    return {
      message: str,
      code: string2phyCode(str)
    };
  };

  jsError2apiError = function(err) {

    /*
    * `err` [Error]
     */
    return {
      message: err.message,
      code: string2phyCode(err.message),
      extra: _.omit(err, 'message')
    };
  };

  other2apiError = function(err) {

    /*
    * `err`
     */
    return {
      message: (err != null ? err.message : void 0) || 'Unknown error',
      code: string2phyCode((err != null ? err.message : void 0) || 'Unknown error'),
      extra: _.omit(err || {}, 'message')
    };
  };

  sendResponse = function(res, err, data) {
    var errors, headers, response, statusCode;
    if (res == null) {
      throw new BaldError('BaldInternalError', '`sendResponse()` Arguments invalid.');
    }

    /*
    * `res`
    * `err` [Error/Array of Errors/String/Array of Strings]
    * `data` [Object]
     */
    response = {};
    response.data = data || {};
    statusCode = 200;
    if (err) {
      if (err.constructor === Array) {
        errors = err;
      } else {
        errors = [err];
      }
      errors = errors.map(function(error) {
        if (typeof error === 'string') {
          return string2apiError(error);
        } else if (error instanceof Error) {
          return jsError2apiError(error);
        } else {
          return other2apiError(error);
        }
      });
      response.errors = errors;
      statusCode = 400;
    }
    headers = {
      'content-type': 'application/json; charset=utf-8'
    };
    return res.set(headers).status(statusCode).end(JSON.stringify(response));
  };

  module.exports = {
    sendResponse: sendResponse,
    other2apiError: other2apiError,
    jsError2apiError: jsError2apiError,
    string2phyCode: string2phyCode,
    string2apiError: string2apiError
  };

}).call(this);