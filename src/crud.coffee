
# This Module provides functions to 
# create, update, delete and get entities
# from mongodb.

# The module also support REST and websocket
# interfaces for crud.

# To set up the REST interface do the following:

# <code>
# app.use '/rest/end/point', require('entity.js').getApp(<entityname>)
# </code>

MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID

# Connect to the mongodb instance. Connecting here
# will cache or reuse the same connections throughout 
# the application

mdb = null
MongoClient.connect "mongodb://localhost:27017/Entity",  { native_parser:true, auto_reconnect: true }, (err, db) ->
  if !err
    mdb = db

# Create an entity
#
# The function takes the following arguments
# entityName - string 
# entityValue - entity object
# callBack - function
exports.create = (entityName, entityValue, callBack) ->
  mdb.collection entityName, (err, col) ->
    if !err
      col.save entityValue, callBack
    else
      callBack err, col


# Update an entity
# 
# The function takes the following arguments:  
# entityName - string  
# entityValue - entity object  
# callBack - function  
exports.update = (entityName, entityId, entityValue, callBack) ->
  mdb.collection entityName, (err, col) ->
    if !err
      delete entityValue._id
      col.update {"_id": new ObjectID(entityId)}, entityValue, {upsert: true}, (err, item) ->
        callBack err, item
    else
      callBack err, col

# Query entities
# 
# entityName - string  
# query - mongodb query  
# callBack - function
exports.get = (entityName, query, callBack) ->
  mdb.collection entityName, (err, col) ->
    if !err
      col.find query, (err, cursor) ->
        if !err
          cursor.toArray (err, items) ->
            callBack err, items
        else
          callBack err, cursor
    else
      callBack err, col

# GET single item with the help of this function
exports.getId = (entityName, id, callBack) ->
  mdb.collection entityName, (err, col) ->
    if !err
      col.findOne {"_id": new ObjectID(id)}, (err, item) ->
        if !item
          callBack err, {}
        else
          callBack err, item
    else
      callBack err, col

# Delete Entity with id
exports.delete = (entityName, id, callBack) ->
  mdb.collection entityName, (err, col) ->
    if !err
      col.remove {"_id": new ObjectID(id)}, (err) ->
        callBack err
    else
      callBack err, col


# The following module.export returns and app
# that provides the REST interface for an Entity
exports.getApp = (name) ->
  express = require('express')
  app = express()
      
  getQuery = (requestQuery) ->    
    query = {}

    for key, value of requestQuery
      if !isNaN(Number value)
        query[key] = Number value
      else if key is '_id'
        query[key] = ObjectID value
      else
        query[key] = value
    
    return query
    
  # Query items from root url
  # by sending query parameters
  # in the get request
  app.get '/', (req, res) ->
      
    query = getQuery req.query
    
    exports.get name, query, (err, items) ->
      if err
        res.send 400, "something went wrong"
      else
        res.send items
  
  # Get a single item by sending GET 
  # request to root url
  app.get '/:id', (req, res) ->
    exports.getId name, req.param('id'), (err, item) ->
      if !err
        res.send item
      else
        res.send 400, 'Something went wrong!'
        
  # Post to root to create one entity
  # the JSON object of the entity is 
  # sent in request body
  app.post '/', (req, res) ->

    exports.create name, req.body, (err, item) ->
      if !err
        res.send item
      else 
        res.send 400, 'Something went wrong!'
  
  # Delete item by sending http delete
  # to the entity uri
  app.delete '/:id', (req, res) ->
    exports.delete name, req.param('id'), (err) ->
      if !err
        res.send {}
      else
        res.send 400, "Something went wrong!"
  
  # To update send the new values in
  # request body to the entity url
  app.put '/:id', (req, res) ->

    exports.update name, req.param('id'), req.body, (err, item) ->
      if !err
        res.send item
      else 
        res.send 400, 'Something went wrong!'
    
  app
  
