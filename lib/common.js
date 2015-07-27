// Generated by CoffeeScript 1.8.0
(function() {
  var async, _;

  _ = require('underscore');

  async = require('async');

  module.exports = function() {
    var makeOperation, sendResponse;
    sendResponse = function(res, err, data) {
      var headers, response, statusCode;
      response = {};
      if (data) {
        response.data = data;
      }
      statusCode = 200;
      if (err != null) {
        response.error = err;
      }
      headers = {
        'content-type': 'application/json; charset=utf-8'
      };
      return res.set(headers).status(statusCode).end(JSON.stringify(response));
    };
    makeOperation = function(action) {
      var operation;
      return operation = function() {
        var operationDone, originalArgs, valueArgs;
        originalArgs = [].slice.call(arguments);
        valueArgs = originalArgs.slice(0, -1);
        operationDone = originalArgs.slice(-1)[0];
        return async.waterfall([
          function(done) {
            var next;
            if (operation.before != null) {
              next = function() {
                return done(null, [].slice.call(arguments));
              };
              return operation.before.apply(null, valueArgs.concat(next));
            } else {
              return done(null, valueArgs);
            }
          }, function(newValueArgs, done) {
            var next;
            next = function() {
              if (operation.after == null) {
                operationDone.apply(null, [].slice.call(arguments));
              }
              return done(null, [].slice.call(arguments));
            };
            return action.apply(null, newValueArgs.concat(next));
          }, function(dataArgs, done) {
            var next;
            if (operation.after != null) {
              next = function() {
                operationDone.apply(null, [].slice.call(arguments));
                return done();
              };
              return operation.after.apply(null, dataArgs.concat(next).concat([valueArgs]));
            } else {
              return done();
            }
          }
        ]);
      };
    };
    return {
      sendResponse: sendResponse,
      makeOperation: makeOperation
    };
  };

}).call(this);