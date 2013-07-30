CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=master)](https://travis-ci.org/ksnabb/cruds)

**CRUDS** aims to provide a fast and easy way to create and expose mongodb 
collections for crud functionality through a RESTful interface and through websockets. It also provides
*subscribe* *unsubscribe* methods with the help of websockets for real-time applications. 


**CRUDS** depends on [express](http://expressjs.com) and [socket.io](http://socket.io) to create
the REST and Websocket endpoints. The REST is fully compatible with [backbone.js](http://backbonejs.org) models.
All code is released under the MIT license and can be found on [github](http://github.com/ksnabb/cruds)

1. Install with **npm** `npm install cruds`

2. In your express app `cruds = require("cruds")(<optional mongodb connection string>)`

3. Set endpoints with `cruds.set(name, app?, socketio?)`

The 'cruds.set' function will create a socket.io namespace for the passed in name and a REST interface 
for '/name' of which both are optional.

    cruds = (connectionString) ->
        mongodb = require "mongodb"
        express = require "express"

__connect(callback)_ is a helper funtion to connect to
mongodb and to cache the connection. Multiple calls to 
connect will in this way not produce more connections
then one call to connect. The callback function will
receive the mongo database instance object.

        _mdb = null

        _connect = (callback) ->
            if _mdb
                callback _mdb
                return

            connectionString = "mongodb://localhost:27017/Entity" if not connectionString
            mongodb.MongoClient.connect connectionString,  { native_parser: true, auto_reconnect: true }, (err, db) =>
                if !err
                    _mdb = db
                    callback _mdb


        class Entity


Create an Entity by passing it a name. The RESTful endpoints will be created at '/#{@name}' and the
socket.io namespace will also use the passed in name for the created entity.

            constructor: (@name) ->

Handle module internal events with *on* and *trigger*.

            listeners: {}

            on: (eventType, callback) ->
                if @listeners[eventType]
                    @listeners[eventType].push callback
                else
                    @listeners[eventType] = [callback]

            trigger: (eventType, args...) ->
                list = @listeners[eventType]
                if list
                    args.unshift eventType
                    for listener in list
                        listener args...

_exists(query, callback)_ is a helper function to check if any results exists with the given query. The callback will be called
with true if it exists and with false otherwise.

            exists: (query, callback) ->
                _connect (mdb) =>
                    mdb.collection @name, (err, col) ->

                        td = col.find(query, {_id: 1}).limit 1

                        td.count true, (err, count) ->
                            callback count is 1

## CRUD functions

The **CRUDS** module exposes functions to do simple crud calls to mongodb collections.

###Create an entity

The *create* function takes the following arguments

- **doc** {Object}, The mongodb document to be created
- **[source]** {Object}, Optional source of the caller of this function
- **[callback]** {function}, Optional callback function

            create: (doc, args...) ->

                callback = args.pop() or () ->
                source = if args.length then args.shift() else null

                _connect (mdb) =>
                    mdb.collection @name, (err, col) =>
                        if !err
                            cb = (err, results) =>
                                callback err, results, source
                                @trigger 'create', results, source

                            col.insert doc, cb
                        else
                            callback err, col

###Update an entity

The *update* function will update the queried document with the 
key value pairs that is given leaving all non mentioned key value 
pairs untouched.
  
- **id** {String}, The hexadecimal representation of a mongodb ObjectID    
- **doc** {Object}, The part of the document that should be updated
- **[source]** {Object}, Optional source of the caller of this function
- **[callback]** {function}, callback function     

            update: (id, doc, args...) ->

                callback = args.pop() or () ->
                source = if args.length then args.shift() else null

                _connect (mdb) =>
                    mdb.collection @name, (err, col) =>
                        if !err
                            delete doc._id
                            oid = new mongodb.ObjectID(id)
                            col.update {"_id": oid}, {$set: doc}, (err, count) =>
                                if count is 0
                                    callback {'error': 404}
                                else
                                    doc._id = oid
                                    callback err, doc, source
                                    @trigger 'update', [doc], source
                        else
                            callback err, col

###Query entities

There are two functions to query entities. One takes
and arbitrary mongodb json formated query *get* and 
the other returns one document according to its id *getById*.
 
The get function accepts following arguments:

- **query** {Object}, mongodb query  
- **options** {Object}, mongodb node.js driver options  
- **callback** {function}, callback function  

            get: (query, options, callback) ->

                _connect (mdb) =>
                    mdb.collection @name, (err, col) ->
                        if !err
                            col.find query, options or {}, (err, cursor) ->
                                if !err
                                    cursor.toArray (err, items) ->
                                        callback err, items
                                else
                                    callback err, cursor
                        else
                            callback err, col

The *getById* function returns one item from mongodb
and it accepts the following arguments:

- **id** {String}, id in ObjectId hex representation  
- **callback** {function}, callback function 

            getById: (id, callback) ->
                _connect (mdb) =>
                    mdb.collection @name, (err, col) ->
                        if !err
                            col.findOne {"_id": new mongodb.ObjectID(id)}, (err, item) ->
                                if !item
                                    callback err, {}
                                else
                                    callback err, item
                        else
                            callback err, col

### Delete entities

The del function deletes one entity at the time

- **id** {String}, id in hex  
- **[callback]** {function}, callback function
    
            del: (id, callback) ->

                if not callback
                    callback = () ->

                _connect (mdb) =>
                    mdb.collection @name, (err, col) =>
                        if !err
                            @trigger 'delete', {"_id": id}
                            col.remove {"_id": new mongodb.ObjectID(id)}, (err) ->
                                callback err
                        else
                            callback err, col


### Request listener application

The *setApp* method sets up a RESTful interface
for the passed express application.

            setApp: (@app) ->
                app = express()

All messages from and to the RESTful interface are in JSON format and are parsed with the 
bodyParser middleware.

                app.use express.bodyParser()

#### URL parameters

The url parameters are parsed with the help of the parseQuery function.

The URI request takes the following parameters

- **query**, Stringified JSON object that is passed directly to mongodb find as a query parameter  
- **options**, Stringified JSON object that is passed to the mongodb node.js find function as the options parameter  

                parseQuery = (requestParam) ->
                    query = {} #default
                    options = {} #default
                    query = JSON.parse requestParam.query if requestParam.query
                    options = JSON.parse requestParam.options if requestParam.options

                    {query: query, options: options}

#### HTTP GET

Query items by sending query parameters as defined above to the root "/" of the REST interface.

                app.get '/', (req, res) =>
        
                    q = parseQuery req.query
            
                    @get q.query, q.options, (err, items) ->
                        if err
                            res.send 400, "something went wrong"
                        else
                            res.send items
      
Get a single item by sending a GET request to the items url "/:id"

                app.get '/:id', (req, res) =>

                    @getById req.param('id'), (err, item) ->
                        if !err
                            res.send item
                        else
                            res.send 400, 'Something went wrong!'

#### HTTP Post

Post to "/" to create a entity. The POST will return the id of the newly created entity.

                app.post '/', (req, res) =>

                    @create req.body, (err, results) ->
                        if !err
                            res.json 201, {_id: results[0]._id}
                        else 
                            res.json 400, {error: 'Creating the document did not work!'}

#### HTTP DELETE

Delete item by sending http delete to the entity url "/:id"

                app.del '/:id', (req, res) =>

                    @del req.param('id'), (err) ->
                        if !err
                            res.send {}
                        else
                            res.send 400, "Something went wrong!"

#### HTTP PUT

To update send the new values in request body to the entity url "/:id"

                app.put '/:id', (req, res) =>

                    @update req.param('id'), req.body, (err, doc) =>
                        if !err
                            res.json 200, null
                        else 
                            res.json 404, 'Something went wrong!'
            
                @app.use "/#{@name}", app

            setSocketio: (socketio) ->

                namespace = "/#{@name}"

Socket.io rooms are used to handle subscriptions to queries. The handler function
handles create and update events.

                handler = (eventType, results, source) =>

                    rooms = socketio.sockets.manager.rooms

                    for roomid, sockets of rooms

                        spl = roomid.split("/")
                        if spl.length < 3
                            continue
                        query = spl[spl.length - 1]
                        q = JSON.parse query
                        q._id = results[0]._id

                        ((eventType, query, item, instance, socket) ->

                            instance.exists q, (bool) ->

                                if bool
                                    socket.broadcast
                                        .to(query)
                                        .emit eventType, item

                        )(eventType, query, results[0], @, source)

                @on 'create', handler
                @on 'update', handler

                socketio
                    .of(namespace)
                    .on 'connection', (socket) =>


#### socket.io create

Create documents by sending 'create' message together with a JSON object. The emit will
get a response with the id of the newly created entity or an error.

                        socket.on 'create', (data) =>

                            @create data, socket, (err, results) ->
                                if !err
                                    socket.emit 'create', {_id: results[0]._id}
                                else 
                                    socket.emit 'create', {'error': 400}

#### socket.io udpate

Update a document by sending a 'update' message with an object including a '_id' and the
key values to be updated.

                        socket.on 'update', (data) =>

                            id = data._id
                        
                            if not id
                                socket.emit {'error': 400}
                            else
                                @update id, data, socket, (err, count) =>

                                    if err
                                        socket.emit 'update', err


#### socket.io get

Query documents by sending an object with *query* and *options* key value pairs.

- **query** {Object}, mongodb query object
- **options** {Object}, mongodb options object

                        socket.on 'get', (data) =>

                            if data.query and data.query._id
                                data.query._id = new mongodb.ObjectID(data.query._id)

                            @get data.query or {}, data.options or {}, (err, items) ->
                                socket.emit 'get', items

#### Socket.io delete

Delete item by sending an object with the items _id.

                        socket.on 'delete', (data) =>
                            @del data._id

#### Socket.io subscribe

Subscribing to entities is done by passing a mongodb query. The socket will
get notifications of events that are returned by the query. The subscription also
handles sending notifications about creation of new documents that fit the query.

                        socket.on 'subscribe', (query) ->
                            socket.join JSON.stringify query


#### Socket.io unsubscribe

The unsubscribe works the same way as the subscribe and will unsubscribe from all documents that
fit the query object.

                        socket.on 'unsubscribe', (query) ->
                            socket.leave JSON.stringify query


#### Socket.io rooms

To get a list of all rooms currently subscribed to the client can send a getrooms message.

                        socket.on 'rooms', ->
                            rooms = socketio.sockets.manager.roomClients[socket.id]
                            socket.emit 'rooms', rooms

The disconnect event cleans up the mess.

                        socket.on 'disconnect', ->
                            socket.removeAllListeners()




### Setup of url endpoints for REST and websockets

To be able to set up both a RESTful interface and a websocket interface 
the *set* method can be used.

- **name** {String}, name of the entity and endpoint url. e.g. if name is 'user' the url will be '/user' 
- **app** {Object}, Express application  
- **socketio** {Object}, Socket.io Server that is set up to listen to a node.js httpserver  
        
        set = (name, app, socketio) ->

Create the Entity instance that handles the transactions.

            entity = new Entity(name)

If the app is passed as null or undefined a REST interface will not be setup.

            if app
                entity.setApp app

Set up the websocket interface and provide the same REST methods _get_, _create_, _update_, _delete_, _subscribe_ and _unsubscribe_.

            if socketio
                entity.setSocketio socketio

### Exposed functions

The CRUDS will expose the following methods.

        set: set
        Entity: Entity

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

  
