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

// updateMultiple gets an JSON encoded array containing the objects
// of the entries to be edited, only mandatory field is "id"
//  e.g. [{"id":"2","name":"a"},{"id":"3","name":"b"}]
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

  // next() can be called without any arguments
  // if you do not want to modify the values
  next(values);
}

userManager.create.after = function(result) {
  console.log('This will be executed after creating a user.');
  // the argument `result` will be a Sequelize
  // object resulting from the operation
}
```

### REST API

Available routes are listed below:

Manager | Method | URL | Description
------- | -------|-----| ------------
userManager.list | GET | /api/Users | Displays all users
userManager.read | GET | /api/Users/1 | Displays a user, searched by id
userManager.updateMultiple | PUT | /api/Users | Edits multiple users (JSON format)
userManager.update | PUT | /api/Users/1 | Edits a user
userManager.create | POST | /api/Users | Adds a user
userManager.del | DELETE | /api/Users/1 | Deletes a user

### Custom endpoints

You can declare your own endpoints instead of letting bald pluralize the model's name. In order to do so you'll have to declare the bald resource in the following way:

```javascript
userManager = bald.resource({
  model: userModel
  endpoints: {
    plural: '/api/CoolUsers'
    singular: '/api/CoolUsers/:id'
  }
});
```

Please note that the singular must include the `id` query parameter in the string. If you are specifiyign custom endpoints, both singular and plural endpoints are mandatory.

### Mentions

Developed at [Phyramid](http://phyramid.com)

### LICENSE

The MIT License (MIT)

Copyright (c) 2015 Petru-Sebastian Toader

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
