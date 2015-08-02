Sequelize = require('sequelize')
http = require('http')
express = require('express')
bodyParser = require('body-parser')
chai = require('chai')
request = require('request')
expect = chai.expect


Bald = require('../src')
ApiTools = require('../src/apiTools')
Common = require('../src/common')
Association = require('../src/association')

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
    test.app.use (err, req, res, next) ->
      console.log 'test'
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

  test.dbError = new Sequelize 'error', '', '',
    host: '∂'

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

    test.models.UserError = test.dbError.define 'User',
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

        test.userErrorResource = test.bald.resource model: test.models.UserError

        test.familyResource = test.bald.resource
          model: test.models.Family

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

  it 'should throw an error when declaring invalid endpoints', (done) ->
    data =
      model: test.models.User
      endpoints: ''
    expect(test.bald.resource.bind(test.bald, data)).to.throw('Invalid endpoints.')
    done()

  it 'should declare accept custom endpoints', (done) ->
    data =
      model: test.models.User
      endpoints: {singular: 'blah', plural: 'blahs'}
      
    expect(test.bald.resource.bind(test.bald, data)().list?).to.eql(true)
    done()

  it 'should throw an error when declaring invalid middleware', (done) ->
    data =
      model: test.models.User
      middleware: ''
    expect(test.bald.resource.bind(test.bald, data)).to.throw('Invalid middleware array provided.')
    done()

  it 'should accept declared middleware', (done) ->
    data =
      model: test.models.User
      middleware:
        'lista': [->]

    expect(test.bald.resource.bind(test.bald, data)().list?).to.eql(true)
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
      it 'should exist', (done) ->
        expect(test.userResource.create?).to.eql(true)
        done()
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
      it 'should throw an error when an Sequelize error is thrown', (done) ->
        test.userErrorResource.create {username: 'a'}, (err, data) ->
          expect(err?).to.eql(true)
        done()
    describe 'list', ->
      it 'should exist', (done) ->
        expect(test.userResource.list?).to.eql(true)
        done()

      it 'should return a sequelize entry when used', (done) ->
        test.familyResource.create {name: 'a'}, (err, data) ->
          test.familyResource.list {}, (err, data) ->
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
      it 'should throw an error when an Sequelize error is thrown', (done) ->
        test.userErrorResource.list {}, (err, data) ->
          expect(err?).to.eql(true)
        done()


    describe 'read', ->
      it 'should exist', (done) ->
        expect(test.userResource.read?).to.eql(true)
        done()
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
      it 'should throw an error when an Sequelize error is thrown', (done) ->
        test.userErrorResource.read {}, (err, data) ->
          expect(err?).to.eql(true)
        done()
    describe 'update', ->
      it 'should exist', (done) ->
        expect(test.userResource.update?).to.eql(true)
        done()
      it 'should return a sequelize entry when used', (done) ->
        test.familyResource.create {name: 'a'}, (err, data) ->
          test.familyResource.update 1, {name: 'b'}, (err, data) ->
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
      it 'should throw an error when an Sequelize error is thrown', (done) ->
        test.userErrorResource.update 1, {}, (err, data) ->
          expect(err?).to.eql(true)
        done()

    describe 'updateMultiple', ->
      it 'should exist', (done) ->
        expect(test.userResource.updateMultiple?).to.eql(true)
        done()
      it 'should return a sequelize entry when used', (done) ->
        test.familyResource.create {name: 'a'}, (err, data) ->
          test.familyResource.create {name: 'b'}, (err, data) ->
            test.familyResource.updateMultiple [{id: 1, name: 'c'},{id:2, name: 'd'}], (err, data) ->
              expect(data[0].name == 'c' && data[1].name == 'd').to.eql(true)
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
      it 'should throw an error when an Sequelize error is thrown', (done) ->
        test.userErrorResource.updateMultiple [{id:1}], (err, data) ->
          expect(err?).to.eql(true)
        done()

    describe 'delete', ->
      it 'should exist', (done) ->
        expect(test.userResource.del?).to.eql(true)
        done()
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
      it 'should throw an error when an Sequelize error is thrown', (done) ->
        test.userErrorResource.del 1, (err, data) ->
          expect(err?).to.eql(true)
        done()
  describe 'REST API', ->
    describe 'list', ->
      it 'should list data when called', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users"
          method: "GET"
        test.userResource.create {username: 'Alfred'}, (err, data) ->
          test.userResource.create {username: 'P Diddy'}, (err, data) ->
            request requestData, (res, err, body) ->
              data = JSON.parse body
              expect(data.data.length).to.eql(2)
              done()
    describe 'read', ->
      it 'should read data when called', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users/1"
          method: "GET"
        test.userResource.create {username: 'Alfred'}, (err, data) ->
          request requestData, (res, err, body) ->
            data = JSON.parse body
            expect(data.data.username).to.eql('Alfred')
            done()
    describe 'create', ->
      it 'should create data when called', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users"
          form:
            username: 'Alfred'
          method: "POST"
        request requestData, (res, err, body) ->
          data = JSON.parse body
          expect(data.data.username).to.eql('Alfred')
          done()
    describe 'update', ->
      it 'should update data when called', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users/1"
          form:
            username: 'Alfred'
          method: "PUT"
        test.userResource.create {username: 'Lupin'}, (err, data) ->
          request requestData, (res, err, body) ->
            data = JSON.parse body
            expect(data.data.username).to.eql('Alfred')
            done()
      it 'aaa', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users/1"
          form:
            username: 'Alfred'
            'Family.add': 1
          method: "PUT"
        test.familyResource.create {name: 'Bepo'}, (err, data) ->
          test.userResource.create {username: 'Lupin'}, (err, data) ->
            request requestData, (err, res, body) ->
              data = JSON.parse body
              expect(res.statusCode).to.eql(400)
              done()

    describe 'updateMultiple', ->
      it 'should create data when called', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users"
          form:
            values: '[{"id": "1", "username": "Alfred"},{"id": "2", "username": "John"}]'
          method: "PUT"
        test.userResource.create {username: 'Lupin'}, (err, data) ->
          test.userResource.create {username: 'Dior'}, (err, data) ->
            request requestData, (res, err, body) ->
              data = JSON.parse body
              expect(data.data[0].username == 'Alfred' && data.data[1].username == 'John').to.eql(true)
              done()

      it 'should throw an error when provided invalid json', (done) ->
        userManager = test.bald.resource
          model: test.models.User
          eagerLoading: true

        requestData =
          url: "#{test.baseUrl}/api/Users"
          form:
            values: 'o'
          method: "PUT"
        userManager.create {username: 'Dior'}, (err, data) ->
          request requestData, (err, res, body) ->
            expect(res.statusCode).to.eql(400)
            done()

    describe 'delete', ->
      it 'should delete data when called', (done) ->
        requestData =
          url: "#{test.baseUrl}/api/Users/1"
          method: "DELETE"
        test.userResource.create {username: 'Lupin'}, (err, data) ->
          request requestData, (res, err, body) ->
            data = JSON.parse body
            expect(data.data).to.eql(1)
            done()
  describe 'Associations', ->
    it 'should throw an error when attempting to associate with an inexistent resource', (done) ->
      expect(Association.attempt.bind(Association, [null, null, null, null])).to.throw('Attempted to associate with an inexistent resource.')
      done()
    it 'should throw an error when a attempt is made with a non-existent model name', (done) ->
      test.userResource.create {username: 'Alfred'}, (err, data) ->
        attempt = Association.attempt.bind(Association, test.models.Friend, data, {'User.set': 1}, () ->)
        expect(attempt).to.throw('User does not exist, try singularizing or pluralizing it!')
        done()

    it 'should throw an error when an undefined association is attempted', (done) ->
      test.userResource.create {username: 'Alfred'}, (err, data) ->
        attempt = Association.associateModels.bind(Association, [{name: {singular: 'User', plural: 'Users'}, method: 'set', value: 1}], data, test.models.User, () ->)
        expect(attempt).to.throw('Association unavailable.')
        done()

    it 'should throw an error when an unavailable model association method is attempted', (done) ->
      test.userResource.create {username: 'Alfred'}, (err, data) ->
        attempt = Association.associateModels.bind(Association, [{name: {singular: 'Family', plural: 'Family'}, method: 'add', value: 1}], data, test.models.User, () ->)
        expect(attempt).to.throw('Method unavailable for model.')
        done()
    describe 'hasOne relations', ->
      it 'should be able to associate two models with a hasOne relation', (done) ->
        test.familyResource.create {name: 'Adams'}, (err, data) ->
          test.userResource.create {username: 'Morty', 'Family.set': data.id}, (err, data) ->
            expect(data.get(null, {plain: true}).Family?).to.eql(true)
            done()
      it 'should be able to associate two models with a hasOne relation in a reverse manner', (done) ->
        test.userResource.create {username: 'Morty'}, (err, data) ->
          test.familyResource.create {name: 'Adams', 'User.set': 1}, (err, data) ->
            test.familyResource.read 1, (err, data) ->
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
  describe 'Route error handling', ->
    describe 'sendResponse()', ->
      it 'should return an error code when `res` is not provided', (done) ->
        expect(ApiTools.sendResponse.bind(ApiTools, null)).to.throw('Arguments invalid.')
        done()
      it 'should return true when sending a `phy-code`', (done) ->
        test.app.get '/', (req, res) ->
          expect(ApiTools.sendResponse(res, 'phy-test', [])).to.eql(true)
          done()
        request test.baseUrl
      it 'should return true when sending an error instance', (done) ->
        test.app.get '/', (req, res) ->
          err = new Error 'phy-test'
          expect(ApiTools.sendResponse(res, err, [])).to.eql(true)
          done()
        request test.baseUrl
      it 'should return true when sending an array as an error', (done) ->
        test.app.get '/', (req, res) ->
          err = new Error 'phy-test'
          expect(ApiTools.sendResponse(res, [{code: 'phy-test'}], false)).to.eql(true)
          done()
        request test.baseUrl
      it 'should return true when sending an array as an error', (done) ->
        test.app.get '/', (req, res) ->
          err = new Error 'phy-test'
          expect(ApiTools.sendResponse(res, [{code: 'phy-test'}], [])).to.eql(true)
          done()
        request test.baseUrl

    describe 'string2phyCode()', ->
      it 'should return a string if it has a `phy-` suffix', (done) ->
        expect(typeof ApiTools.string2phyCode.bind(ApiTools, 'phy-test')()).to.eql('string')
        done()
      it 'should return null if it doesn\'t have a `phy-` suffix', (done) ->
        expect(ApiTools.string2phyCode.bind(ApiTools, 'JP Morgan')()).to.eql(null)
        done()
    describe 'string2apiError()', ->
      it 'should return an object with message', (done) ->
        expect(ApiTools.string2apiError.bind(ApiTools, 'phy-test')().message?).to.eql(true)
        done()
      it 'should return an object with code', (done) ->
        expect(ApiTools.string2apiError.bind(ApiTools, 'phy-test')().code?).to.eql(true)
        done()
    describe 'jsError2apiError()', ->
      it 'should return an object with message', (done) ->
        err = new Error 'phy-test'
        expect(ApiTools.jsError2apiError.bind(ApiTools, err)().message?).to.eql(true)
        done()
      it 'should return an object with code', (done) ->
        err = new Error 'phy-test'
        expect(ApiTools.jsError2apiError.bind(ApiTools, err)().message?).to.eql(true)
        done()
      it 'should return an object with extra', (done) ->
        err = new Error 'phy-test'
        expect(ApiTools.jsError2apiError.bind(ApiTools, err)().message?).to.eql(true)
        done()
    describe 'other2apiError()', ->
      it 'should return an object with message', (done) ->
        err = 'an error'
        expect(ApiTools.other2apiError.bind(ApiTools, err)().message?).to.eql(true)
        done()
      it 'should return an object with code', (done) ->
        err = 'an error'
        expect(ApiTools.other2apiError.bind(ApiTools, err)().message?).to.eql(true)
        done()
      it 'should return an object with extra', (done) ->
        err = 'an error'
        expect(ApiTools.other2apiError.bind(ApiTools, err)().message?).to.eql(true)
        done()
    describe 'handleError()', ->
      it 'should throw an error when catching an error', (done) ->
        expect(Common.handleError.bind(Common, new Error 'oops', ->)).to.throw('oops')
        done()
