CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=master)](https://travis-ci.org/ksnabb/cruds)

**CRUDS** aims to provide a fast and easy way to create and expose mongodb 
collections for basic crud functionality. Supports HTTP, WebSockets and 
SSE (EventSource). The websockets and SSE also supports subscribe and unsubscribe
funcationality for real-time messaging.

Note that this module is only intended for fast prorotype development.

    express = require "express"
    fs = require "fs"
    gridform = require "gridform"
    mongoose = require "mongoose"
    path = require "path"
    _ = require "underscore"
    WebSocketServer = require('ws').Server

When creating a CRUDS you can pass in an options object. All parameters set by the options
object are optional.

The following parameters can be set:

- **[name]** {String}, The name for the Entity which will be the name of the mongodb collection, default is "Entity"
- **[schema]** {Object}, Equals the Mongoose schema object, if not set the Entity will be schemaless, default is schemaless {}
- **[server]** {Object}, A ndoe js server that will be used to create the websocket connections
- **[ConnectionString]** {String}, The mongodb connection string to be used, defaults to "mongodb://localhost:27017/cruds"

    cruds = (options) ->

        unless options
            options = {}

Name of the Entity which will be used as the mongodb collection name

        name = if options.name then options.name else "Entity"

Mongoose schema to be used to validate the uploads etc.

        schema = if options.schema then options.schema else new mongoose.Schema({}, {strict:false})

Websocket is supported if a server instance is passed in

        wss = if options.server then new WebSocketServer {server: options.server, path: "/#{name}"} else null


        fs.mkdir path.join(__dirname, "../uploads"), (err) ->
            fs.mkdir path.join(__dirname, "../uploads/#{name}"), (err) ->
                #do nothing

        mongoose.connect (if options.connectionString then options.connectionString else "mongodb://localhost:27017/cruds"), (err) ->
            if err
                console.warn """
                    You might have tried to create two endpoints with the same name. 
                    Pass in a name option to get rid of this error.

                    The original error was
                    """, err
            else
                gridform.db = mongoose.connection.db
                gridform.mongo = mongoose.mongo


        class Entity

            constructor: (@model) ->
                @sockets = []
                @subscriptions = {}

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
                        doc = {"_id": doc.toObject()._id}
                        callback err, doc

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


### Subscribe 

The subscribe method can be used to get notifications of entity changes that fit certain query.

            subscribe: (ws, channel) ->
                ws.channels.push channel
                if @subscriptions["c-#{channel}"]
                    @subscriptions["c-#{channel}"].push ws.id
                else
                    @subscriptions["c-#{channel}"] = [ws.id]

### Unsubscribe

            unsubscribe: (ws, channel) ->

                i = ws.channels.indexOf channel
                if i > -1
                    ws.channels.splice i, 1

                    i = @subscriptions["c-#{channel}"].indexOf ws.id
                    if i > -1
                        @subscriptions["c-#{channel}"].splice i, 1

### Exist function
            
The exist function checks if a certain query would return any documents.

            exists: (query, callback) ->

                @model.find query, '_id', {'limit': 1}, (err, doc) ->
                    if callback
                        callback err, (doc.length is 1)


### Entity router

The router handles all the requests. Make sure no bodyparser or multipart middleware is used
for this one to work for now.

            route: (req, res) =>

                if req.method is "GET"
                    id = req.params.id
                    query = req.query
                    if id
                        query['_id'] = id
                    @get query, (err, docs) ->
                        res.json 200, docs
                        
                else if req.method is "DELETE"
                    @del req.param.id, (err) ->
                        res.json 200, {}

                else

                    contentType = req.get 'content-type'
                    isMultipart = contentType.search("multipart/form-data") > -1

                    if isMultipart
                        form = new gridform()

                        onPart = (gridPart, part) ->
                            if not part.filename? or (part.filename and part.filename isnt "")
                                gridPart.call this, part

                        nativePart = form.onPart
                        form.onPart = onPart.bind form, nativePart
                        
                        form.parse req, (err, fields, files) =>
                            doc = _.extend fields, files

                            if req.method is "POST"
                                @create doc, (err, doc) ->
                                    res.json 201, doc
                            else if req.method is "PUT"
                                @update req.params.id, doc, (err, doc) ->
                                    res.json 200, {}

                    else if req.method is "POST"
                        @create req.body, (err, doc) ->
                            res.json 201, doc

                    else if req.method is "PUT"
                        @update req.param.id, req.body, (err, doc) ->
                            res.json 200, {}

                    else
                        res.json {message: "request method #{req.method} not supported"}


            fileRoute: (req, res) ->
                id = req.params.id
                readstream = gridform.gridfsStream(mongoose.connection.db, mongoose.mongo).createReadStream id

                readstream.on 'error', (err) ->
                    console.error('An error occurred!', err)
                    throw err

                readstream.pipe res

### WebSockets 

The websocket server will be set with this function

            routews: (ws) =>

                ws.id = "" + Date.now() + Math.floor(Math.random() * 1000)
                ws.channels = []

                @sockets.push ws

                handleMessage = (message, flags) ->


                    message = JSON.parse message

Messages received can include timestamps that should also be attached to the
reponse so the client knows which request is responded to.

                    ts = 0
                    if message.ts
                        ts = message.ts

                    if message.method is "create"
                        @create message.doc, (err, doc) ->
                            response = {
                                ts: ts
                                data: doc
                            }
                            ws.send JSON.stringify response

                    else if message.method is "read"    
                        @get message.query, (err, docs) ->
                            response = {
                                ts: ts
                                data: docs
                            }
                            ws.send JSON.stringify response

                    else if message.method is "update"
                        @update message.id, message.doc, (err, doc) ->
                            response = {ts: ts}
                            ws.send JSON.stringify response

                    else if message.method is "delete"
                        @del message.id, (err, doc) ->
                            response = {ts: ts}
                            ws.send JSON.stringify response

                    else if message.method is "subscribe"
                        @subscribe ws, message.channel
                        response = {ts: ts}
                        ws.send JSON.stringify response

                    else if message.method is "subscriptions"
                        response = {
                            ts: ts
                            data: ws.channels
                        }
                        ws.send JSON.stringify response

                    else if message.method is "unsubscribe"
                        @unsubscribe ws, message.channel
                        response = {
                            ts: ts
                        }
                        ws.send JSON.stringify response
                        
                    else
                        response = {
                            ts: ts
                            data: "method not supported"
                        }
                        ws.send JSON.stringify response

                ws.on 'message', handleMessage.bind @


** Return this stuff and maybe write something about it**
        
        model = mongoose.model name, schema

        entity = new Entity(model)
        wss.on 'connection', entity.routews if wss

        app = new express()
        app.all "/#{name}/file/:id", entity.fileRoute
        app.all "/#{name}/:id", entity.route
        app.all "/#{name}", entity.route
        return {
            entity: entity
            app: app
        }

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

  
