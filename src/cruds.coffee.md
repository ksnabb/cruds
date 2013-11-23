CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=master)](https://travis-ci.org/ksnabb/cruds)

**CRUDS** aims to provide a fast and easy way to create and expose mongodb 
collections for crud functionality through a RESTful interface and websockets. The websockets
interface also supports real-time subscribe and unsubscribe functionality.


** TODO UPDATE THIS PART WITH DEPENDENCIES **

** ADD INSTALLATION AND SETUP INSTRUCTIONS **

    cruds = (options) ->

        class Entity

## CRUD functions

The **CRUDS** module exposes functions to do simple crud calls to mongodb collections.

###Create an entity

The *create* function takes the following arguments

- **doc** {Object}, The mongodb document to be created
- **[callback]** {function}, Optional callback function

            create: (doc, args...) ->

###Update an entity

The *update* function will update the queried document with the 
key value pairs that is given leaving all non mentioned key value 
pairs untouched.
      
- **doc** {Object}, The part of the document that should be updated
- **[callback]** {function}, callback function     

            update: (doc, args...) ->

###Query entities

There are two functions to query entities. One takes
and arbitrary mongodb json formated query *get* and 
the other returns one document according to its id *getById*.
 
The get function accepts following arguments:

- **query** {Object}, mongodb query  
- **options** {Object}, mongodb node.js driver options  
- **callback** {function}, callback function  

            get: (query, options, callback) ->

The *getById* function returns one item from mongodb
and it accepts the following arguments:

- **id** {String}, id in ObjectId hex representation  
- **callback** {function}, callback function 

            getById: (id, callback) ->

### Delete entity

The del function deletes one entity at the time

- **id** {String}, id in hex  
- **[callback]** {function}, callback function
    
            del: (id, callback) ->
            

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

  
