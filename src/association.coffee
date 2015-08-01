inflect = require 'inflect'
async = require 'async'
util = require 'util'

associateModels = (targetModels, sourceData, sourceModel, next) ->
  processAssociation = (targetModelData, done) ->
    models = sourceModel.sequelize.models

    association = sourceModel.associations[targetModelData.name.plural] ||
                  sourceModel.associations[targetModelData.name.singular]

    throw new Error 'Association unavailable' if !association?

    targetModel = association.target || association.target
    throw new Error 'Model unavailable' if !targetModel?

    targetMethod = association.accessors?[targetModelData.method] ||
                   association[targetModelData.method]
    throw new Error 'Method unavailable for model' if !targetMethod?

    query = {}
    query.where = {}
    query.where[targetModel.primaryKeyField] = targetModelData.value

    targetModel.findAll(query).then (targetData) ->
      targetData = targetData[0] if typeof targetModelData.value != 'object'
      sourceData[targetMethod](targetData).then (res) -> done(null, res)

  async.map targetModels, processAssociation, (err, res) ->
    next(null, sourceData)

attempt = (sourceModel, sourceData, values, next) ->
  throw new Error 'Attempted to associate with an inexistent resource.' if !sourceData?

  filteredValues = Object.keys(values).filter (key) ->
    modelName = key.split('.')[0] if key.split('.').length == 2
    return false if !modelName?

    return sourceModel.associations[modelName]? ||
      sourceModel.associations[inflect.pluralize(modelName)]?

  targetModels = filteredValues.map (value) ->
    data = value.split('.')
    name = sourceModel.associations[data[0]]?.options.name
    throw new Error data[0] + ' does not exist, try singularizing or pluralizing it!' if !name?
    try
      queryValue = JSON.parse values[value]
    catch
      queryValue = values[value]

    return {name: name, method: data[1], value: queryValue}

  return next null, sourceData if targetModels.length == 0
  associateModels targetModels, sourceData, sourceModel, next

module.exports = {
  attempt
}
