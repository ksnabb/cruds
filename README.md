CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=master)](https://travis-ci.org/ksnabb/cruds)

**CRUDS** aims to provide a fast and easy way to create and expose mongodb 
collections for crud functionality through REST and websockets with optional real-time 
subscribe and unsubscribe functionality throught a websocket interface. **CRUDS** depends on [express](http://expressjs.com) and [socket.io](http://socket.io) to create
the REST and Websocket endpoints. The REST is fully compatible with [backbone.js](http://backbonejs.org) models.

1. Install with **npm** `npm install cruds`

2. In your express app `cruds = require("cruds")(<optional mongodb connection string>)`

3. Set endpoints with `cruds.set(name, app?, socketio?)`

More documentation can be found [here](http://ksnabb.github.io/cruds/).

A GIST on how to make CRUDS work with express and socket.io can be found [here](https://gist.github.com/ksnabb/6142680).
