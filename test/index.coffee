http = require('http')
express = require('express')
bodyParser = require('body-parser')
chai = require('chai')
request = require('request')
expect = chai.expect

Bald = require('../lib/Resource')
ApiTools = require('../lib/ApiTools')

chai.config.includeStack = true

Fixture =
  initializeServer: (done) ->
    Fixture.app = express()
    Fixture.app.use(bodyParser.json())
    Fixture.app.use(bodyParser.urlencoded({ extended: false }))
    Fixture.server = http.createServer(Fixture.app)

    Fixture.server.listen 0, '127.0.0.1', () ->
      Fixture.baseUrl =
        "http://#{Fixture.server.address().address}:#{Fixture.server.address().port}"
      done()

describe 'Bald initialization', ->
  it 'should throw an exception when initilized without arguments', (done) ->
    expect((-> new Bald {})).to.throw('Arguments invalid.')
    done()

describe 'Bald resources', ->
  before ->
    Fixture.knex = require('knex')
      client: 'sqlite3'
      connection:
        filename: ':memory:'

    Fixture.knex.schema
      .createTableIfNotExists 'User', (table) ->
        table.increments('id').primary()
        table.string('name')

  beforeEach (done) ->
    Fixture.initializeServer ->
      Fixture.bald = new Bald app: Fixture.app, knex: Fixture.knex
      Fixture.bald.resource model: 'User'
      Fixture.bald.resource model: 'MissingTable'
      done()

  it 'should throw an exception when a resource is initialized without a model', (done) ->
    expect(Fixture.bald.resource.bind(Fixture.bald, {})).to.throw('Invalid model.')
    done()

  it 'should declare accept custom endpoints', (done) ->
    data =
      model: 'User'
      endpoints: {singular: 'blah', plural: 'blahs'}
    expect(Fixture.bald.resource.bind(Fixture.bald, data)).to.not.throw(Error)
    done()

  it 'should throw an error when declaring invalid middleware', (done) ->
    data =
      model: 'User'
      middleware: ''
    expect(Fixture.bald.resource.bind(Fixture.bald, data)).to.throw('Invalid middleware array provided.')
    done()

  it 'should accept declared middleware', (done) ->
    data =
      model: 'User'
      middleware:
        'list': [->]

    expect(Fixture.bald.resource.bind(Fixture.bald, data)).to.not.throw(Error)
    done()

  describe 'REST API', ->
    describe 'list', ->
      it 'should list data when called', (done) ->
        requestData =
          url: "#{Fixture.baseUrl}/api/Users"
          method: "GET"
        Fixture.knex('User')
          .insert(name: 'Alfred')
          .then((data) ->
            request requestData, (res, err, body) ->
              data = JSON.parse body
              expect(data.data.length).to.eql(1)
              done()
          ).catch(done)

    describe 'read', ->
      it 'should read data when called', (done) ->
        requestData =
          url: "#{Fixture.baseUrl}/api/User/1"
          method: "GET"
        request requestData, (res, err, body) ->
          data = JSON.parse body
          expect(data.data.name).to.eql('Alfred')
          done()
    describe 'create', ->
      it 'should create data when called', (done) ->
        requestData =
          url: "#{Fixture.baseUrl}/api/Users"
          form:
            name: 'Alfredo'
          method: "POST"
        request requestData, (res, err, body) ->
          data = JSON.parse body
          expect(data.data.id).to.eql(2)
          expect(data.data.name).to.eql('Alfredo')
          done()
    describe 'update', ->
      it 'should update data when called', (done) ->
        requestData =
          url: "#{Fixture.baseUrl}/api/User/1"
          form:
            name: 'Lupin'
          method: "PUT"

        request requestData, (res, err, body) ->
          data = JSON.parse body
          expect(data.data.name).to.eql('Lupin')
          done()

    describe 'delete', ->
      it 'should delete data when called', (done) ->
        requestData =
          url: "#{Fixture.baseUrl}/api/User/2"
          method: "DELETE"
        request requestData, (res, err, body) ->
          data = JSON.parse body
          expect(data.data).to.eql(1)
          done()

  describe 'Route error handling', ->
    describe 'sendResponse()', ->
      it 'should return an error code when `res` is not provided', (done) ->
        expect(ApiTools.sendResponse.bind(ApiTools, null)).to.throw('Arguments invalid.')
        done()
      it 'should return true when sending a `phy-code`', (done) ->
        Fixture.app.get '/', (req, res) ->
          expect(ApiTools.sendResponse(res, 'phy-test', [])).to.eql(true)
          done()
        request Fixture.baseUrl
      it 'should return true when sending an error instance', (done) ->
        Fixture.app.get '/', (req, res) ->
          err = new Error 'phy-test'
          expect(ApiTools.sendResponse(res, err, [])).to.eql(true)
          done()
        request Fixture.baseUrl
      it 'should return true when sending an array as an error', (done) ->
        Fixture.app.get '/', (req, res) ->
          err = new Error 'phy-test'
          expect(ApiTools.sendResponse(res, [{code: 'phy-test'}], false)).to.eql(true)
          done()
        request Fixture.baseUrl
      it 'should return true when sending an array as an error', (done) ->
        Fixture.app.get '/', (req, res) ->
          err = new Error 'phy-test'
          expect(ApiTools.sendResponse(res, [{code: 'phy-test'}], [])).to.eql(true)
          done()
        request Fixture.baseUrl

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
