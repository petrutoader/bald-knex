Sequelize = require('sequelize')
http = require('http')
express = require('express')
bodyParser = require('body-parser')
chai = require('chai')
expect = chai.expect

Bald = require('../src')

chai.config.includeStack = true

test =
  models: {}
  Sequelize: Sequelize
  initializeDatabase: (done) ->
    test.db
      .sync({force: true})
      .then () -> done()

  initializeServer: (done) ->
    test.app = express()
    test.app.use(bodyParser.json())
    test.app.use(bodyParser.urlencoded({ extended: false }))
    test.server = http.createServer(test.app)

    test.server.listen 0, '127.0.0.1', () ->
      test.baseUrl =
        'http://' + test.server.address().address + ':' + test.server.address().port
      done()

  clearDatabase: (done) ->
    test.db
      .getQueryInterface()
      .dropAllTables()
      .then () -> done()

before ->
  test.db = new Sequelize 'main', null, null,
    dialect: 'sqlite'
    storage: ':memory:'
    logging: false

describe 'Bald initialization', ->
  it 'should throw an exception when initilized without arguments', (done) ->
    expect(Bald.bind(Bald, {})).to.throw('Arguments invalid.')
    done()

describe 'Bald resources', ->
  before ->
    test.models.User = test.db.define 'User',
      username:
        type: test.Sequelize.STRING
        allowNull: false
      email:
        type: test.Sequelize.STRING
        unique: msg: 'not-unique'
        validate: isEmail: true

    test.models.Family = test.db.define 'Family',
      name:
        type: test.Sequelize.STRING
        allowNull: false

    test.models.Cloth = test.db.define 'Cloth',
      name:
        type: test.Sequelize.STRING
        allowNull: false

    test.models.Friend = test.db.define 'Friend',
      name:
        type: test.Sequelize.STRING
        allowNull: false

    test.models.Document = test.db.define 'Document', {}

    test.models.User.hasOne test.models.Family
    test.models.User.hasMany test.models.Cloth
    test.models.Friend.belongsToMany test.models.User, through: 'IncludesFriend'

    test.models.Document.belongsTo test.models.User, as: 'DocumentIssuer', foreignKey: 'DocumentIssuerId'
    test.models.Document.belongsTo test.models.User, as: 'DocumentRecepient', foreignKey: 'DocumentRecepientId'

    test.models.Family.belongsTo test.models.User
    test.models.Cloth.belongsTo test.models.User

    test.models.User.belongsToMany test.models.Friend, through: 'IncludesFriend'

    test.models.User.hasMany test.models.Document, as: 'IssuedDocument', foreignKey: 'DocumentIssuerId'
    test.models.User.hasMany test.models.Document, as: 'ReceivedDocument', foreignKey: 'DocumentRecepientId'

  beforeEach (done) ->
    test.initializeDatabase ->
      test.initializeServer ->
        test.bald = new Bald
          app: test.app,
          sequelize: test.Sequelize

        test.userResource = test.bald.resource
          model: test.models.User
          eagerLoading: true

        test.familyResource = test.bald.resource
          model: test.models.Family
          eagerLoading: true

        test.clothResource = test.bald.resource
          model: test.models.Cloth
          eagerLoading: true

        test.friendResource = test.bald.resource
          model: test.models.Friend
          eagerLoading: true

        test.documentResource = test.bald.resource
          model: test.models.Document
          eagerLoading: true

        done()

  afterEach (done) ->
    test.clearDatabase () ->
      test.server.close done

  it 'should throw an exception when a resource is initialized without a model', (done) ->
    expect(test.bald.resource.bind(test.bald, {})).to.throw('Invalid model.')
    done()

  it 'should generate a manager object', (done) ->
    expect(test.userResource.list?).to.eql(true)
    done()

  it 'should generate a manager with list, create, update, updateMultiple, delete and read', (done) ->
    expect(Object.keys(test.userResource).length).to.eql(6)
    done()

  it 'should eagerly load data if eagerLoading is active', (done) ->
    test.familyResource.create {name: 'Adams'}, (err, data) ->
      test.userResource.create {username: 'Morty', 'Family.set': data.id}, (err, data) ->
        expect(data.get(null, {plain: true}).Family?).to.eql(true)
        done()

  describe 'Methods', ->
    describe 'create', ->
      it 'should return a sequelize entry when used', (done) ->
        test.userResource.create {username: 'a'}, (err, data) ->
          expect(data.dataValues?).to.eql(true)
          done()
      it 'should be able to alter flow when before functions are defined', (done) ->
        test.userResource.create.before = (values, next) ->
          values.username = 'James Bond'
          next(values)
        test.userResource.create {}, (err, data) ->
          expect(data.username).to.eql('James Bond')
          done()
      it 'should be able to alter flow when after functions are defined', (done) ->
        test.userResource.create.after = (err, data, next) ->
          data.username = 'James Bond'
          next(err, data)
        test.userResource.create {username: 'Tom Hanks'}, (err, data) ->
          expect(data.username).to.eql('James Bond')
          done()
      it 'should provide an Sequelize error when failing validation', (done) ->
        test.userResource.create {}, (err, data) ->
          expect(err?).to.eql(true)
          done()
    describe 'list', ->
      it 'should return a sequelize entry when used', (done) ->
        test.userResource.create {username: 'a'}, (err, data) ->
          test.userResource.list {}, (err, data) ->
            expect(data[0].dataValues?).to.eql(true)
            done()
      it 'should be able to alter flow whne before functions are defined', (done) ->
        test.userResource.list.before = (values, next) ->
          values = {limit: 1, offset: 0}
          next(values)
        test.userResource.create {username: 'The Pope'}, (err, data) ->
          test.userResource.create {username: 'Vargo The Barbarian'}, (err, data) ->
            test.userResource.list {}, (err, data) ->
              expect(data.length).to.eql(1)
              done()
      it 'should be able to alter flow when after functions are defined', (done) ->
        test.userResource.list.after = (err, data, next) ->
          next(err, data[0])

        test.userResource.create {username: 'The Pope'}, (err, data) ->
          test.userResource.create {username: 'Vargo The Barbarian'}, (err, data) ->
            test.userResource.list {}, (err, data) ->
              expect(data.dataValues?).to.eql(true)
              done()
      it 'should be able to offset and limit results', (done) ->
        test.userResource.create {username: 'The Pope'}, (err, data) ->
          test.userResource.create {username: 'Vargo The Barbarian'}, (err, data) ->
            test.userResource.list {offset: 1, limit:1}, (err, data) ->
              expect(data[0].dataValues.username).to.eql('Vargo The Barbarian')
              done()
      it 'should be able to sort results', (done) ->
        test.userResource.create {username: 'The Pope'}, (err, data) ->
          test.userResource.create {username: 'Vargo The Barbarian'}, (err, data) ->
            test.userResource.list {sortBy: 'username', sort: 'DESC'}, (err, data) ->
              expect(data[0].id).to.eql(2)
              done()
      it 'should be able to filter results', (done) ->
        test.userResource.create {username: 'Vargo The Barbarian'}, (err, data) ->
          test.userResource.create {username: 'The Pope'}, (err, data) ->
            test.userResource.list {filterBy: 'username', filter: 'The Pope'}, (err, data) ->
              expect(data[0].id).to.eql(2)
              done()

    describe 'read', ->
      it 'should return a sequelize entry when used', (done) ->
        test.userResource.create {username: 'a'}, (err, data) ->
          test.userResource.read {id: 1}, (err, data) ->
            expect(data.dataValues?).to.eql(true)
            done()
      it 'should be able to alter flow when before functions are defined', (done) ->
        test.userResource.read.before = (values, next) ->
          values = {id: 1}
          next(values)
        test.userResource.create {username: 'The Pope'}, (err, data) ->
          test.userResource.read {id: 1945}, (err, data) ->
            expect(data.dataValues?).to.eql(true)
            done()
      it 'should be able to alter flow when after functions are defined', (done) ->
        test.userResource.read.after = (err, data, next) ->
          data.username = 'Rasputin'
          next(err, data)

        test.userResource.create {username: 'The Pope'}, (err, data) ->
          test.userResource.read {id: 1}, (err, data) ->
            expect(data.username).to.eql('Rasputin')
            done()

    describe 'update', ->
      it 'should return a sequelize entry when used', (done) ->
        test.userResource.create {username: 'a'}, (err, data) ->
          test.userResource.update 1, {username: 'b'}, (err, data) ->
            expect(data.dataValues?).to.eql(true)
            done()
      it 'should be able to alter flow when before functions are defined', (done) ->
        test.userResource.update.before = (id, values, next) ->
          values.username = 'James Bond'
          next(id, values)

        test.userResource.create {username: 'Bill Clinton'}, (err, data) ->
          test.userResource.update 1, {}, (err, data) ->
            expect(data.username).to.eql('James Bond')
            done()
      it 'should be able to alter flow when after functions are defined', (done) ->
        test.userResource.update.after = (err, data, next) ->
          data.username = 'James Bond'
          next(err, data)
        test.userResource.create {username: 'Tony Montana'}, (err, data) ->
          test.userResource.update 1, {username: 'Tom Hanks'}, (err, data) ->
            expect(data.username).to.eql('James Bond')
            done()
      it 'should provide an Sequelize error when failing validation', (done) ->
        test.userResource.create {username: 'Tony Montana'}, (err, data) ->
          test.userResource.update 1, {email: 'Tom Hanks'}, (err, data) ->
            expect(err?).to.eql(true)
            done()

    describe 'updateMultiple', ->
      it 'should return a sequelize entry when used', (done) ->
        test.userResource.create {username: 'a'}, (err, data) ->
          test.userResource.create {username: 'b'}, (err, data) ->
            test.userResource.updateMultiple [{id: 1, username: 'c'},{id:2, username: 'd'}], (err, data) ->
              expect(data[0].username == 'c' && data[1].username == 'd').to.eql(true)
              done()
      it 'should be able to alter flow when before functions are defined', (done) ->
        test.userResource.updateMultiple.before = (values, next) ->
          values[0].id = 1
          next(values)

        test.userResource.create {username: 'Bill Clinton'}, (err, data) ->
          test.userResource.create {username: 'Justin Bieber'}, (err, data) ->
            test.userResource.updateMultiple [{id: 10, username: 'Jim'},{id: 2, username: 'Juicy J'}],(err, data) ->
              expect(data[0].username).to.eql('Jim')
              done()
      it 'should be able to alter flow when after functions are defined', (done) ->
        test.userResource.updateMultiple.after = (err, data, next) ->
          data[0].username = 'James Bond'
          next(err, data)
        test.userResource.create {username: 'Tony Montana'}, (err, data) ->
          test.userResource.create {username: 'Tony Montana'}, (err, data) ->
            test.userResource.updateMultiple [{id: 1, username: 'Tom Hanks'}], (err, data) ->
              expect(data[0].username).to.eql('James Bond')
              done()

      it 'should provide an Sequelize error when failing validation', (done) ->
        test.userResource.create {username: 'Tony Montana'}, (err, data) ->
          test.userResource.updateMultiple [{id: 1, email: 'Tom Hanks'}], (err, data) ->
            expect(err?).to.eql(true)
            done()

    describe 'delete', ->
      it 'should return a sequelize entry when used', (done) ->
        test.userResource.create {username: 'a'}, (err, data) ->
          test.userResource.del 1, (err, data) ->
            expect(data).to.eql(1)
            done()
      it 'should be able to alter flow when before functions are defined', (done) ->
        test.userResource.del.before = (id, next) ->
          next(1)

        test.userResource.create {username: 'Bill Clinton'}, (err, data) ->
          test.userResource.del 1912, (err, data) ->
            expect(data).to.eql(1)
            done()
      it 'should be able to alter flow when after functions are defined', (done) ->
        test.userResource.del.after = (err, data, next) ->
          data = 'James Bond'
          next(err, data)
        test.userResource.create {username: 'Tony Montana'}, (err, data) ->
          test.userResource.del 1, (err, data) ->
            expect(data).to.eql('James Bond')
            done()
  describe 'Associations', ->
    describe 'hasOne relations', ->
      it 'should be able to associate two models with a hasOne relation', (done) ->
        test.familyResource.create {name: 'Adams'}, (err, data) ->
          test.userResource.create {username: 'Morty', 'Family.set': data.id}, (err, data) ->
            expect(data.get(null, {plain: true}).Family?).to.eql(true)
            done()
      it 'should be able to associate two models with a hasOne relation in a reverse manner', (done) ->
        test.userResource.create {username: 'Morty'}, (err, data) ->
          test.familyResource.create {name: 'Adams', 'User.set': 1}, (err, data) ->
            expect(data.get(null, {plain:true}).UserId).to.eql(1)
            done()

    describe 'hasMany relations', ->
      it 'should be able to associate two models with a hasMany relation with `set`', (done) ->
        test.clothResource.create {name: 'Pants'}, (err, data) ->
          test.clothResource.create {name: 'Shirts'}, (err, data) ->
            test.clothResource.create {name: 'Hats'}, (err, data) ->
              test.userResource.create {username: 'John', 'Cloths.set': [1,2,3]}, (err, data) ->
                expect(data.get(null, {plain: true}).Cloths.length).to.eql(3)
                done()
      it 'should be able to associate two models with a hasMany relation with `add`', (done) ->
        test.clothResource.create {name: 'Pants'}, (err, data) ->
          test.clothResource.create {name: 'Shirts'}, (err, data) ->
            test.clothResource.create {name: 'Hats'}, (err, data) ->
              test.userResource.create {username: 'John', 'Cloths.add': [1,2,3]}, (err, data) ->
                expect(data.get(null, {plain: true}).Cloths.length).to.eql(3)
                done()

      it 'should be able to deassociate two models with a hasMany relation with `remove` and remove one element', (done) ->
        test.clothResource.create {name: 'Pants'}, (err, data) ->
          test.clothResource.create {name: 'Shirts'}, (err, data) ->
            test.clothResource.create {name: 'Hats'}, (err, cloth) ->
              test.userResource.create {username: 'John', 'Cloths.add': [1,2,3]}, (err, data) ->
                test.userResource.update 1, {username: 'John', 'Cloths.remove': 3}, (err, data) ->
                  expect(data.get(null, {plain: true}).Cloths.length).to.eql(2)
                  done()

      it 'should be able to deassociate two models with a hasMany relation with `remove` and remove multiple elements', (done) ->
        test.clothResource.create {name: 'Pants'}, (err, data) ->
          test.clothResource.create {name: 'Shirts'}, (err, data) ->
            test.clothResource.create {name: 'Hats'}, (err, cloth) ->
              test.userResource.create {username: 'John', 'Cloths.add': [1,2,3]}, (err, data) ->
                test.userResource.update 1, {username: 'John', 'Cloths.remove': [2,3]}, (err, data) ->
                  expect(data.get(null, {plain: true}).Cloths.length).to.eql(1)
                  done()

      it 'should be able to associate two models with a hasMany relation in a reverse manner', (done) ->
        test.userResource.create {username: 'John'}, (err, data) ->
          test.clothResource.create {name: 'Pants', 'User.set': 1}, (err, data) ->
            expect(data.UserId).to.eql(1)
            done()

    describe 'belongsToMany relations', ->
      describe 'through', ->
        it 'should be able to associate two models with a belongsToMany relation with `set`', (done) ->
          test.friendResource.create {name: 'John'}, (err, data) ->
            test.userResource.create {username: 'Alfred', 'Friends.set': 1}, (err, data) ->
              expect(data.Friends.length).to.eql(1)
              done()

        it 'should be able to associate two models with a belongsToMany relation with `add`', (done) ->
          test.friendResource.create {name: 'John'}, (err, data) ->
            test.friendResource.create {name: 'John'}, (err, data) ->
              test.userResource.create {username: 'Alfred', 'Friends.add': [1,2]}, (err, data) ->
                expect(data.Friends.length).to.eql(2)
                done()

        it 'should be able to deassociate two models with a belongsToMany relation with `remove` and remove one element', (done) ->
          test.friendResource.create {name: 'John'}, (err, data) ->
            test.friendResource.create {name: 'Batman'}, (err, data) ->
              test.userResource.create {username: 'John', 'Friends.add': [1,2]}, (err, data) ->
                # John you suck, Batman is cooler.
                test.userResource.update 1, {'Friends.remove': 1}, (err, data) ->
                  expect(data.get(null, {plain: true}).Friends.length).to.eql(1)
                  done()

        it 'should be able to deassociate two models with a belongsToMany relation with `remove` and remove one element', (done) ->
          test.friendResource.create {name: 'John'}, (err, data) ->
            test.friendResource.create {name: 'Snitch'}, (err, data) ->
              test.friendResource.create {name: 'Doe'}, (err, data) ->
                test.userResource.create {username: 'John', 'Friends.add': [1,2,3]}, (err, data) ->
                  test.userResource.update 1, {'Friends.remove': [1,2]}, (err, data) ->
                    expect(data.get(null, {plain: true}).Friends.length).to.eql(1)
                    done()

        it 'should be able to associate two models with a belongsToMany relation in a reverse manner', (done) ->
          test.userResource.create {username: 'Alfred'}, (err, data) ->
            test.friendResource.create {name: 'Carmen', 'Users.set': 1}, (err, data) ->
              expect(data.get(null, {plain:true}).Users.length).to.eql(1)
              done()

      describe 'as', ->
        it 'should be able to associate two models with `as` from the owner with `set`', (done) ->
          test.documentResource.create {}, (err, data) ->
            test.documentResource.create {}, (err, data) ->
              test.userResource.create {username: 'Andrew', 'IssuedDocument.set': 1, 'ReceivedDocument.set': 2}, (err, data) ->
                expect(data.ReceivedDocument.length == 1 && data.IssuedDocument.length == 1).to.eql(true)
                done()
        it 'should be able to associate two models with `as` from the owner with `add`', (done) ->
          test.documentResource.create {}, (err, data) ->
            test.documentResource.create {}, (err, data) ->
              test.userResource.create {username: 'Andrew', 'IssuedDocument.set': [1,2]}, (err, data) ->
                expect(data.IssuedDocument.length == 2).to.eql(true)
                done()
        it 'should be able to associate two model with `as` with `set` in a reverse manner', (done) ->
          test.userResource.create {username: 'PHYRAMID'}, (err, data) ->
            test.userResource.create {username: 'MICROSOFT'}, (err, data) ->
              test.documentResource.create {'DocumentIssuer.set': 1, 'DocumentRecepient.set': 2}, (err, document) ->
                document = document.get(null, plain: true)
                expect(document.DocumentIssuer? && document.DocumentRecepient?).to.eql(true)
                done()
