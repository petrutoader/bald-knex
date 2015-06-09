# bald
REST API using [Sequelize](http://www.sequelizejs.com/) models in [express.js](http://expressjs.com/).

### Getting started
```
Sequelize = require('sequelize')
Bald = require('./bald/src/index.coffee')

express = require('express')
bodyParser = require('body-parser')
http = require('http')

sequelize = new Sequelize('database', 'sqlUser', 'sqlPassword', {host: 'sqlHost'})
userModel = sequelize.define('User', {name: {type: Sequelize.STRING, allowNull: false}})

app = express()
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({extended: false}))

server = http.createServer(app)

bald = new Bald({app, sequelize})

userManager = bald.resource({
  model: userModel
})

sequelize.sync({})
  .then ->
      app.listen(3000)
```

### Managers

You can programmatically call the models once you have defined a bald resource:

```
userManager = bald.resource({
  model: model
})

userManager.list (data) ->
  console.log data
```

This will output the entire list of entries in the model. Available methods are listed below:

```
userManager.create values, (data) ->
  console.log data

userManager.list (data) ->
  console.log data

userManager.read id, (data) ->
  console.log data

userManager.update id, values, (data) ->
  console.log data

userManager.del id, (data) ->
  console.log data
```

### Customize behavior

You can set behavior for each method in the manager to add functionality before and after the execution of the query:

```
userManager.create.before = ->
  console.log 'This will be executed before creating a user.'

userManager.create.after = ->
  console.log 'This will be executed after creating a user.'
```

### REST API

Available routes are listed below:

Method | URL | Description
-------|-----| ------------
GET | /api/Users | Displays all users
GET | /api/Users/1 | Displays one user, searched by id
PUT | /api/Users/1 | Edits one user, values are sent via req.body
POST | /api/Users | Adds one user, values are sent via req.body
DELETE | /api/Users/1 | Deletes one user, searched by id

### Mentions

Developed at [Phyramid](http://phyramid.com)
