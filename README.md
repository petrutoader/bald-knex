# bald
REST API generator using [Sequelize](http://www.sequelizejs.com/) models in [express.js](http://expressjs.com/).

[![npm version](https://badge.fury.io/js/bald.svg)](http://badge.fury.io/js/bald)

### Installing via NPM
```bash
npm install bald
```

### Getting started
```javascript
Sequelize = require('sequelize');
Bald = require('bald');
express = require('express');
bodyParser = require('body-parser');
http = require('http');

sequelize = new Sequelize('database', 'sqlUser', 'sqlPassword', {host: 'sqlHost'});
userModel = sequelize.define('User', {name: {type: Sequelize.STRING}});

app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}));

server = http.createServer(app);

bald = new Bald({app, sequelize});

userManager = bald.resource({
  model: userModel
});

sequelize.sync({}).then(function() {
  app.listen(3000);
});
```

### Managers

You can programmatically call the models once you have defined a bald resource:

```javascript
userManager = bald.resource({
  model: model
});

userManager.list(function(err, data) {
  console.log(data)
});
```

This will output the entire list of entries in the model. Available methods are listed below:

```javascript
userManager.create(values, function(err, data) {
  console.log(data);
});

userManager.list(function(err, data) {
  console.log(data);
});

userManager.read(id, function(err, data) {
  console.log(data);
});

userManager.update(id, values, function(err, data) {
  console.log(data);
});

# updateMultiple gets an JSON encoded array containing the objects
# of the entries to be edited, only mandatory field is "id"
# e.g. [{"id":"2","name":"a"},{"id":"3","name":"b"}]
userManager.updateMultiple(values, function(err, data) {
  console.log(data);
});

userManager.del(id, function(err, data) {
  console.log(data);
});
```

### Middleware support

Bald also optionally includes middleware support for each route that is declared:

```javascript
isUser = function(req, res, next) {
  console.log('isUser checks!');
  next();
};

userManager = bald.resource({
  model: model
  middleware: {
    'list': [isAdmin, isUser],
    'create': [isAdmin, isUser],
    'read': [isUser],
    'update': [isAdmin, isUser],
    'delete': [isAdmin, isUser]
  }
})
```

You do not need to declare all the routes middleware if none is needed.

### Customize behavior

You can set behavior for each method in the manager to add functionality before and after the execution of the query:

```javascript
userManager.create.before = function(values, next) {
  console.log('You can manipulate values here, before creating.');

  # next() can be called without any arguments
  # if you do not want to modify the values
  next(values);
}

userManager.create.after = function() {
  console.log('This will be executed after creating a user.');
}
```

### REST API

Available routes are listed below:

Method | URL | Description
-------|-----| ------------
GET | /api/Users | Displays all users
GET | /api/Users/1 | Displays one user, searched by id
PUT | /api/Users | Edits multiple entries, values are sent via req.body in JSON format
PUT | /api/Users/1 | Edits one user, values are sent via req.body
POST | /api/Users | Adds one user, values are sent via req.body
DELETE | /api/Users/1 | Deletes one user, searched by id

### Mentions

Developed at [Phyramid](http://phyramid.com)
