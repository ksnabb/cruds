CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=master)](https://travis-ci.org/ksnabb/cruds)

**CRUDS** aims to provide a fast and easy way to create and expose mongodb 
collections for crud functionality through REST and websockets with optional real-time 
subscribe and unsubscribe functionality throught the websocket interface. **CRUDS** works together with connect/express 
applications, socket.io and backbone.js with a fully compatible REST interface.

_**CRUDS** is made for fast prototyping purposes do not use it as-is in a production environment_

1. Install with **npm** `npm install cruds`

2. In your express app `cruds = require("cruds")(<optional mongodb connection string>)`

3. Set endpoints with `cruds.set(url, collection name, app?, socketio?)`

    cruds = (connectionString) ->
        mongodb = require "mongodb"
        express = require "express"

Handle module internal events with *_on* and *_trigger*.

        _listeners = {}

        _on = (eventType, callback) ->
            if _listeners[eventType]
                _listeners[eventType].push callback
            else
                _listeners[eventType] = [callback]

        _trigger = (eventType) ->
            list = _listeners[eventType]
            if list
                for listener in list
                    args = Array.prototype.slice.call arguments
                    listener.apply this, args

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
            else
                _on 'connect', () ->
                    callback arguments[1]

            connectionString = "mongodb://localhost:27017/Entity" if not connectionString
            mongodb.MongoClient.connect connectionString,  { native_parser: true, auto_reconnect: true }, (err, db) =>
                if !err
                    _mdb = db
                    _trigger 'connect', _mdb


__exists(entityName, query, callback)_ is a helper function to check if any entity exists with the given query. The callback will be called
with true if exists and with false otherwise.

        _exists = (entityName, query, callback) ->
            _connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    
                    col.find(query).limit(1).count true, (err, count) ->
                        if count > 0
                            callback true
                        else
                            callback false

## CRUD functions

The **CRUDS** module exposes functions to do simple crud calls to mongodb collections.

###Create an entity

The *create* function takes the following arguments

- **name** {String}, name of entity collection   
- **entity** {Object}, entity object  
- **callback** {function}, callback function  

        create = (name, entity, callback) ->
            _connect (mdb) ->
                mdb.collection name, (err, col) ->
                    if !err
                        cb = (err, item) ->
                            callback err, item
                            _trigger 'create', item, 'create'

                        col.save entity, cb
                    else
                        callback err, col

###Update an entity

The *update* function will update the queried document with the 
key value pairs that is given in entityValue leaving all
non mentioned key value pairs untouched. This function
does in other words not replace the queried documents.

- **name** {String}, The name of the collection to use    
- **id** {String}, The hexadecimal representation of a mongodb ObjectID    
- **entity** {Object}, The part of the document that should be updated    
- **callback** {function}, callback function     

        update = (name, id, entity, callback) ->
            _connect (mdb) ->
                mdb.collection name, (err, col) ->
                    if !err
                        delete entity._id
                        oid = new mongodb.ObjectID(id)
                        col.update {"_id": oid}, {$set: entity}, (err, count) =>
                            callback err, count
                            entity._id = oid
                            _trigger 'update', entity, 'update'
                    else
                        callback err, col

###Query entities

There are two function to query entities. One takes
and arbitrary mongodb json formated query *get* and 
the other returns one document according to its id *getById*.
 
The get function takes the following arguments:

- **name** {String}, name of entity collection  
- **query** {Object}, mongodb query  
- **options** {Object}, mongodb node.js driver options  
- **callback** {function}, callback function  

        get = (name, query, options, callback) ->

            _connect (mdb) ->
                mdb.collection name, (err, col) ->
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
and it takes the following arguments:

- **name** {String}, name of entity collection  
- **id** {String}, id in ObjectId hex representation  
- **callback** {function}, callback function 

        getById = (name, id, callback) ->
            _connect (mdb) ->
                mdb.collection name, (err, col) ->
                    if !err
                        col.findOne {"_id": new mongodb.ObjectID(id)}, (err, item) ->
                            if !item
                                callback err, {}
                            else
                                callback err, item
                    else
                        callback err, col

### Delete entities

The del function deletes one entity

- **name** {String}, name of entity collection  
- **id** {String}, id in hex  
- **callback** {function}, callback function
    
        del = (name, id, callback) ->
            _connect (mdb) ->
                mdb.collection name, (err, col) ->
                    if !err
                        _trigger 'delete', {"_id": id}, 'delete'
                        col.remove {"_id": new mongodb.ObjectID(id)}, (err) ->
                            callback err
                    else
                        callback err, col


### Request listener application

The *getApp* method returns and express app that provides
a RESTful interface for the collection with the given name.

        getApp = (name) ->
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

            app.get '/', (req, res) ->
    
                q = parseQuery req.query
        
                get name, q.query, q.options, (err, items) ->
                    if err
                        res.send 400, "something went wrong"
                    else
                        res.send items
      
Get a single item by sending a GET request to the items url "/:id"

            app.get '/:id', (req, res) ->

                getById name, req.param('id'), (err, item) ->
                    if !err
                        res.send item
                    else
                        res.send 400, 'Something went wrong!'

#### HTTP Post

Post to "/" to create a entity. The JSON object of the entity is sent in request body

            app.post '/', (req, res) ->

                create name, req.body, (err, item) ->
                    if !err
                        res.send item
                    else 
                        res.send 400, 'Something went wrong!'

#### HTTP DELETE

Delete item by sending http delete to the entity url "/:id"

            app.del '/:id', (req, res) ->

                del name, req.param('id'), (err) ->
                    if !err
                        res.send {}
                    else
                        res.send 400, "Something went wrong!"

#### HTTP PUT

To update send the new values in request body to the entity url "/:id"

            app.put '/:id', (req, res) ->

                update name, req.param('id'), req.body, (err, count) ->

                    if !err and count is 1
                        getById name, req.param('id'), (err, item) ->
                            if !err
                                res.send item
                            else
                                res.send 400, 'Something went wrong!'
                    else if count is 0
                        res.send 404
                    else 
                        res.send 400, 'Something went wrong!'
        
            app


### Setup of url endpoints for REST and websockets

To be able to set up both a RESTful interface and a websocket interface 
the *set* method can be used. 

- **url** {String}, endpoint for the request  
- **name** {String}, name of the entity to use for saving to the database  
- **app** {Object}, Express application  
- **socketio** {Object}, Socket.io Server that is set up to listen to a node.js httpserver  
        
        set = (url, name, app, socketio) ->

If the app is passed as null or undefined a REST interface will not be setup.

            if app
                app.use url, getApp(name)

Socket.io rooms are used to handle subscriptions to queries. The handler function
handles create and update events.

            handler = (eventType, item) ->
                rooms = socketio.sockets.manager.rooms

                for roomid, sockets of rooms
                    spl = roomid.split("/")
                    query = spl[spl.length - 1]

                    query._id = item._id

                    _exists name, query, (bool) ->
                        if bool
                            socketio.of(url)
                                .in(query)
                                .emit eventType, item

Set up the websocket interface and provide the same REST methods _get_, _create_, _update_, _delete_, _subscribe_ and _unsubscribe_.

            if socketio
                _on 'create', handler
                _on 'update', handler

                socketio
                    .of(url)
                    .on 'connection', (socket) ->

#### socket.io create

Create documents by sending 'create' message together with a JSON object.

                        socket.on 'create', (data) ->

                            create name, data, (err, item) ->
                                if !err
                                    socket.emit 'create', data
                                else 
                                    socket.emit 'create', {'error': 400}

#### socket.io udpate

Update a document by sending a 'update' message with an object including and '_id' and the
key values to be updated.

                        socket.on 'update', (data) ->

                            id = data._id
                        
                            if not id
                                socket.emit {'error': 400}
                            else
                                update name, id, data, (err, count) ->

                                    if !err and count is 1
                                        getById name, id, (err, item) ->
                                            if !err
                                                socket.emit 'update', item
                                                socketio.of(url).in(item._id).emit 'supdate', item
                                            else
                                                socket.emit 'update', {'error': 400}
                                    else if count is 0
                                        socket.emit 'update', {'error': 404}
                                    else
                                        socket.emit 'update', {'error': 400}

#### socket.io get

Query documents by sending an object with *query* and *options* key value pairs.

- **query** {Object}, mongodb query object
- **options** {Object}, mongodb options object

                        socket.on 'get', (data) ->

                            get name, data.query or {}, data.options or {}, (err, items) ->
                                socket.emit 'get', items

#### Socket.io delete

Delete item by sending an object with the items _id.

                        socket.on 'delete', (data) ->

                            del name, data._id, (err) ->
                                socket.emit 'delete', {}

#### Socket.io subscribe

Subscribing to entities is done by passing a mongodb query. The socket will
get notifications of events that are returned by the query. The subscription also
handles sending notifications about creation of new documents that fit the query.

                        socket.on 'subscribe', (query) ->

                            socket.join JSON.stringify query
                            socket.emit 'subscribed', ''


#### Socket.io unsubscribe

The unsubscribe works the same way as the subscribe and will unsubscribe from all documents that
fit the query object.

                        socket.on 'unsubscribe', (query) ->

                            socket.leave JSON.stringify query
                            socket.emit 'unsubscribed', ''


#### Socket.io rooms

To get a list of all rooms currently subscribed to the client can send a getrooms message.

                        socket.on 'rooms', () ->
                            rooms = socketio.sockets.manager.roomClients[socket.id]
                            socket.emit 'rooms', rooms


### Exposed functions

The CRUDS will expose the following methods.

        {'set': set,
        'getApp': getApp,
        'create': create,
        'update': update,
        'get': get,
        'del': del,
        'getById': getById
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

  
