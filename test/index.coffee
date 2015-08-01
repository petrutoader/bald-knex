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

describe 'Bald', ->
  it 'should throw an exception when initilized without arguments', (done) ->
    expect(Bald.bind(Bald, {})).to.throw('Arguments invalid.')
    done()

describe 'Bald resources', ->
  before ->
    test.models.User = test.db.define 'Users',
      username:
        type: test.Sequelize.STRING
        allowNull: false
      email:
        type: test.Sequelize.STRING
        unique: msg: 'not-unique'
        validate: isEmail: true

  beforeEach (done) ->
    test.initializeDatabase ->
      test.initializeServer ->
        test.bald = new Bald
          app: test.app,
          sequelize: test.Sequelize
        test.userResource = test.bald.resource
          model: test.models.User,
          endpoints: ['/users', '/users/:id']
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
