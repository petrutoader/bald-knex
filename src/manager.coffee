makeOperation = (action) ->
  operation = ->
    operation.hooks.before.map (h) -> h()
    action.apply(null, arguments)
    operation.hooks.after.map (h) -> h()

  operation.hooks = {
    before: []
    after: []
  }

  operation.addHook = (name, fn) ->
    operation.hooks[name].push(fn)

  operation.before = (fn) ->
    operation.addHook('before', fn)

  operation.after = (fn) ->
    operation.addHook('after', fn)

  return operation

module.exports = (model) ->
  create = makeOperation (values, done) ->
    model.create(values)
      .then((data) -> done(null, data))
      .catch(done)

  list = makeOperation (done) ->
    model.findAll({})
      .then((data) -> done(null, data))
      .catch(done)

  read = makeOperation (id, done) ->
    model.find({where: {id: id}})
      .then((data) -> done(null, data))
      .catch(done)

  update = makeOperation (id, values, done) ->
    model.update(values, {where: {id: id}})
      .then((data) -> done(null, data))
      .catch(done)

  del = makeOperation (id, done) ->
    model.destroy({where: {id: id}})
      .then((data) -> done(null, data))
      .catch(done)

  return {
    create
    list
    read
    update
    del
  }
