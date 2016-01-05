# bald
REST API generator using [knex](http://www.knexjs.org/) for [express.js](http://expressjs.com/).

[![NPM](https://nodei.co/npm/bald-knex.png?downloads=true)](https://nodei.co/npm/bald-knex/)

[![Build Status](https://travis-ci.org/petrutoader/bald-knex.svg?branch=master)](https://travis-ci.org/petrutoader/bald-knex)
[![Dependency Status](https://david-dm.org/petrutoader/bald-knex.svg)](https://david-dm.org/petrutoader/bald-knex)


### Installing via NPM
```bash
npm install bald-knex
```

### Getting started

Using bald is really easy, let's take the following example:

We have a table called `Users` we'd like to expose to the API:

```javascript
bald = new Bald({app: app, knex: knex})

bald.resource({
  model: 'Users'
});
```

That's it! You can now create, read, update and delete using the newly created API. You can check them at `/api/Users/` and `/api/Users/:pk` where `:pk` is the primary key of the table.

### Primary keys

Sometimes you may want to set a different primary key than `id`, for that you can set the `primaryKey` parameter in the resource initialization as follows:

```javascript
bald.resource({
  model: 'Users'
  primaryKey: 'id'
})
```

### Middleware support

Bald also optionally includes middleware support for each route that is declared:

```javascript
isUser = function(req, res, next) {
  console.log('isUser checks!');
  next();
};

bald.resource({
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

#### HTTP

Following the same method as in the manager, you `PUT` or `POST` the data to the endpoint with `x-www-form-urlencoded`.

### REST API

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
    singular: '/api/CoolUser/:id'
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
