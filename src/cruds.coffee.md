CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=master)](https://travis-ci.org/ksnabb/cruds)

**CRUDS** aims to provide a fast and easy way to create and expose mongodb 
collections for crud functionality through a RESTful interface and websockets. The websockets
interface also supports real-time subscribe and unsubscribe functionality.


** TODO UPDATE THIS PART WITH DEPENDENCIES **

    mongoose = require "mongoose"

When creating a CRUDS you can pass in an options object. All parameters set by the options
object are optional but some of them are highly recommended to use.

The following parameters can be set:

- **[name]** {String}, The name for the Entity which will be the name of the mongodb collection, default is "Entity"
- **[schema]** {Object}, Equals the Mongoose schema object, if not set the Entity will be schemaless, default is schemaless {}
- **[ConnectionString]** {String}, The mongodb connection string to be used, defaults to "mongodb://localhost:27017/cruds"

    cruds = (options) ->

        unless options
            options = {}

        name = if options.name then options.name else "Entity"
        schema = if options.schema then options.schema else new mongoose.Schema({}, {strict:false})

        mongoose.connect (if options.connectionString then options.connectionString else "mongodb://localhost:27017/cruds"), (err) ->
            if err
                console.warn """
                    You might have tried to create two endpoints with the same name. 
                    Pass in a name option to get rid of this error.

                    The original error was
                    """, err

        class Entity

            constructor: (@model) ->

## CRUD functions

The **CRUDS** module exposes functions to do simple crud calls to mongodb collections.

###Create an entity

The *create* function will create a new document for the passed in document. The callback will receive the 
values that has changed during the creation of the document as parameters.

- **doc** {Object}, The mongodb document to be created
- **[callback]** {function}, Optional callback function that will get two params err and the changed key value pairs

            create: (doc, callback) ->
                newEntity = new @model doc
                newEntity.save (err, doc) ->
                    if callback and not err
                        callback err, doc.toObject()

###Update an entity

The *update* function will update the queried document with the 
key value pairs that is given leaving all non mentioned key value 
pairs untouched.
      
- **doc** {Object}, The part of the document that should be updated
- **[callback]** {function}, callback function     

            update: (id, doc, callback) ->
                @model.update {'_id': id}, doc, callback


###Query entities

There are two functions to query entities. One takes
and arbitrary mongodb json formated query *get* and 
the other returns one document according to its id *getById*.
 
The get function accepts following arguments:

- **query** {Object}, mongodb query  
- **options** {Object}, mongodb node.js driver options  
- **callback** {function}, callback function  

            get: (query, fields, options, callback) ->
                @model.find query, fields, options, (err, docs) ->
                    callback err, docs

### Delete entity

The del function deletes one entity at the time

- **id** {String}, id in hex  
- **[callback]** {function}, callback function
    
            del: (id, callback) ->
                @model.findByIdAndRemove id, callback

### Exist function
            
The exist function checks if a certain query would return any documents.

            exists: (query, callback) ->

                @model.find query, '_id', {'limit': 1}, (err, doc) ->
                    if callback
                        callback err, (doc.length is 1)


### Entity router

The router handles all the requests.

            route: (req, res) ->

                res.send "hello world"

** Return this stuff and maybe write something about it**
        
        model = mongoose.model name, schema

        return new Entity(model)

    module.exports = cruds

# License

The MIT License (MIT)

Copyright (c) 2013 Kristoffer Snabb

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

  
