# bald
REST API generator using [Sequelize](http://www.sequelizejs.com/) models in [express.js](http://expressjs.com/).

[![NPM](https://nodei.co/npm/bald.png?downloads=true)](https://nodei.co/npm/bald/)


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

userManager.list(options, function(err, data) {
  console.log(data)
});
```

This will output the entire list of entries in the model. Available methods are listed below:

```javascript
userManager.create(values, function(err, data) {
  console.log(data);
});

query = {
  offset: 1
  limit: 15
  sortBy: 'id'
  sort: 'DESC'
  filterBy: 'name'
  filter: 'John'
}

userManager.list(query, function(err, data) {
  console.log(data);
});

// e.g. {id: 1}
userManager.read({property: query}, function(err, data) {
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
  next(values);
}

userManager.create.after = function(err, data, next) {
  // `data` will be the resulting Sequelize object
  console.log('This will be executed after creating a user.');
  next(err, data)
}
```

### Manager and REST API

Available routes are listed below:

Manager | Method | URL | Description
------- | -------|-----| ------------
userManager.list | GET | /api/Users | Displays all users
userManager.read | GET | /api/Users/1 | Displays a user, searched by id
userManager.updateMultiple | PUT | /api/Users | Edits multiple users (JSON format)
userManager.update({id: 1}, ... | PUT | /api/Users/1 | Edits a user
userManager.create | POST | /api/Users | Adds a user
userManager.del | DELETE | /api/Users/1 | Deletes a user

### Custom endpoints

You can declare your own endpoints instead of letting bald pluralize the model's name. In order to do so you'll have to declare the bald resource in the following way:

```javascript
userManager = bald.resource({
  model: userModel,
  endpoints: {
    plural: '/api/CoolUsers'
    singular: '/api/CoolUsers/:id'
  }
});
```

Please note that the singular must include the `id` query parameter in the string. If you are specifiyign custom endpoints, both singular and plural endpoints are mandatory.


### Eager Loading

You may also tell Bald to eagerly load all the data when initializing the resource:

```javascript
userManager = bald.resource({
  model: userModel,
  eagerLoading: true
});
```

### Endpoint data pagination, sorting and filtering

You have multiple filtering, sorting and filtering options, and you may also combine them. A series of filters for the list endpoints are available:

#### Pagination

You can get paginated results by providing via `limit` the element count to be outputed and `offset` to display the results from an offset (e.g.`/api/Users?limit=30&offset=30`).

#### Sorting

You can sort results by providing `sort` (accepts either `asc` or `desc`) and `sortBy` which will sort by a value (e.g. `/api/Users?sortBy=name&sort=desc`)

*Note:* You can provide just `sort` if you want to do just an ascending or descending ordering and will use the `id` field as a `sortBy` parameter.

#### Filtering

You may also filter results by providing `filter` that accepts a string `e.g. John` and `filterBy` which will be the column name in the model (e.g. `/api/Users?filterBy=name&filter=John`)

### TODO

* Add Sequelize association support.

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
