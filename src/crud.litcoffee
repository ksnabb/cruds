    
This Module provides functions to 
create, update, delete and get entities
from mongodb.

The module also provides a RESTfull interfaces for crud.

The interface is fully compatible with backbone.js models.

To use the module just do require("crud")( mongodb connection string )

    module.exports = (mongoDbConnectionString) ->
    
        MongoClient = require('mongodb').MongoClient
        ObjectID = require('mongodb').ObjectID

Functions to return will be created in the 'ex' variable
    
        ex = {}

_connect(callBack)_ is a helper funtion to connect to
mongodb and to cache the connection. Multiple cals to 
connect will in this way not produce more connections
then one call to connect. The callback function will
receive the mongo database instance object.

        mdb = null
        listeners = []
        connect = (callBack) ->
            if mdb
                callBack mdb
                return
            else
                listeners.push callBack

            mongoDbConnectionString = "mongodb://localhost:27017/Entity" if not mongoDbConnectionString
            MongoClient.connect mongoDbConnectionString,  { native_parser: true, auto_reconnect: true }, (err, db) ->
                if !err
                    mdb = db

                for listener in listeners
                    listener mdb

###Create an entity

The function takes the following arguments

_entityName_ - string     
_entityValue_ - entity object     
_callBack_ - function     

        ex.create = (entityName, entityValue, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.save entityValue, callBack
                    else
                        callBack err, col

###Update an entity

The update will update the queried document with the 
key value pairs that is given in entityValue leaving all
non mentioned key value pairs untouched. This function
does not in other words replace the queried documents.

The function takes the following arguments:

_entityName_ - The name of the collection to use    
_entityId_ - The hexadecimal representation of a mongodb ObjectID    
_entityValue_ - The part of the document that should be updated    
_callBack_ - function that takes two arguments error if an error occured and count which is the amount of documents that was updated     

        ex.update = (entityName, entityId, entityValue, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        delete entityValue._id
                        col.update {"_id": new ObjectID(entityId)}, {$set: entityValue}, (err, count) ->
                            callBack err, count
                    else
                        callBack err, col

###Query entities

There are two function to query entities. One takes
and arbitrary mongodb json formated query _get()_ and 
the other returns one item by it's id _getById()_.
 
The get function takes the following parameters:

_entityName_ - name of entity collection 
_query_ - mongodb query
_options_ - mongodb node.js driver options
_callBack_ - callback function

        ex.get = (entityName, query, options, callBack) ->

            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.find query, options or {}, (err, cursor) ->
                            if !err
                                cursor.toArray (err, items) ->
                                    callBack err, items
                            else
                                callBack err, cursor
                    else
                        callBack err, col

The getById function return one item from mongoDb
and it takes the following parameters:

_entityName_ - name of entity collection
_id_ - id in OjectId hex representation
_callBack_ - The callback function that gets error object and item as parameters

        ex.getById = (entityName, id, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.findOne {"_id": new ObjectID(id)}, (err, item) ->
                            if !item
                                callBack err, {}
                            else
                                callBack err, item
                    else
                        callBack err, col

### Delete entities

The del function deletes one entity at the time.

_entityName_ - name of entity collection
_id_ - id in ObjectIf hex representation
_callBack_ - callback that gets a possible error object as argument
    
        ex.del = (entityName, id, callBack) ->
            connect (mdb) ->
                mdb.collection entityName, (err, col) ->
                    if !err
                        col.remove {"_id": new ObjectID(id)}, (err) ->
                            callBack err
                    else
                        callBack err, col


### Express application

The following module.export returns an express app
that provides the REST interface for an Entity

        ex.getApp = (name) ->
            express = require('express')
            app = express()

The application requires json parser or bodyparser middleware to work.

            app.use express.bodyParser()

The GET parameters are parsed with the help of the parseQuery function.
The URI request can have the following parameters:
_query_ - Stringified JSON object that is passed directly to mongodb find as query parameter
_options_ - Stringified JSON object that is the options for nodejs mongodb driver find function

The _methods_ JSON object is and array containing json objects where the key is the cursor method and the value is the
argument passed to the method.

            parseQuery = (requestParam) ->
                query = {} #default
                options = {} #default
                query = JSON.parse requestParam.query if requestParam.query
                options = JSON.parse requestParam.options if requestParam.options

                {query: query, options: options}

Query items from root url
by sending query parameters
in the get request

            app.get '/', (req, res) ->
    
                q = parseQuery req.query
        
                ex.get name, q.query, q.options, (err, items) ->
                    if err
                        res.send 400, "something went wrong"
                    else
                        res.send items
      
Get a single item by sending GET 
request to root url

            app.get '/:id', (req, res) ->

                ex.getById name, req.param('id'), (err, item) ->
                    if !err
                        res.send item
                    else
                        res.send 400, 'Something went wrong!'
              
Post to root to create one entity
the JSON object of the entity is 
sent in request body

            app.post '/', (req, res) ->

                ex.create name, req.body, (err, item) ->
                    if !err
                        res.send item
                    else 
                        res.send 400, 'Something went wrong!'
    
Delete item by sending http delete
to the entity uri

            app.del '/:id', (req, res) ->

                ex.del name, req.param('id'), (err) ->
                    if !err
                        res.send {}
                    else
                        res.send 400, "Something went wrong!"
    
To update send the new values in
request body to the entity url

            app.put '/:id', (req, res) ->

                ex.update name, req.param('id'), req.body, (err, count) ->

                    if !err and count is 1
                        ex.getById name, req.param('id'), (err, item) ->
                            if !err
                                res.send item
                            else
                                res.send 400, 'Something went wrong!'
                    else if count is 0
                        res.send 404
                    else 
                        res.send 400, 'Something went wrong!'
        
            app


### Set up of url endpoints

To be able to set up both a RESTful interface and a websocket interface 
the set method can be used. 

_url_ - endpoint for the request
_name_ - name of the entity to use for saving to the database
_app_ - Express application
_socketio_ - Socket.io that is set up to listen to a httpserver
        
        ex.set = (url, name, app, socketio) ->

set up the REST interface using getApp

            app.use url, ex.getApp(name)

set up the websocket interface and provide the same REST methods GET, CREATE, UPDATE, DELETE and additional SUBSCRIBE

            socketio
                .of(url)
                .on 'connection', (socket) ->

Sending a 'create' messages with the json of the document to be created
will create the document or send and error object back to the client.

                    socket.on 'create', (data) ->

                        ex.create name, data, (err, item) ->
                            if !err
                                socket.emit 'create', data
                            else 
                                socket.emit 'create', {'error': 400}

Updating a document requires the client to send a json that includes the _id for 
the document to be updated.

                    socket.on 'update', (data) ->

                        id = data._id
                    
                        if not id
                            socket.emit {'error': 400}
                        else
                            ex.update name, id, data, (err, count) ->

                                if !err and count is 1
                                    ex.getById name, id, (err, item) ->
                                        if !err
                                            socket.emit 'update', item
                                            socketio.of(url).in(item._id).emit 'supdate', item
                                        else
                                            socket.emit 'update', {'error': 400}
                                else if count is 0
                                    socket.emit 'update', {'error': 404}
                                else
                                    socket.emit 'update', {'error': 400}

                    socket.on 'get', (data) ->

                        ex.get name, data.query or {}, data.options or {}, (err, items) ->
                            socket.emit 'get', items

                    socket.on 'delete', (data) ->

                        ex.del name, data._id, (err) ->

                            socket.emit 'delete', {}

Sending subscribe message requires a object that is the query for documents to subscribe to.
This object is directly used as the query object for mongodb and the returned documents
_id will be the name of the rooms subscribed to.

                    socket.on 'subscribe', (data) ->

                        ex.get name, data or {}, {fields: [{_id: 1}]}, (err, items) ->
                            for item in items
                                socket.join item._id
                                socket.emit 'subscribed', item

The unsubscribe works the same way as the subscribe except that the query and the returned documents
ids will be unsubscribed from.

                    socket.on 'unsubscribe', (data) ->

                        ex.get name, data or {}, {fields: [{_id: 1}]}, (err, items) ->
                            for item in items
                                socket.leave item._id


        ex

  
