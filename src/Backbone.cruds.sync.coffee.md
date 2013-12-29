The Backbone.cruds sync is a drop-in replacement for Backbone.Sync.

Additionally it provides WebSocket and SSE type interfacing for real time
updates for your models and collections.

Set backup of the original sync methods from Backbone.

    Backbone.ajaxSync = Backbone.sync

The getSyncMethods function will return the appropriate method to use for each case
separatelly.

The Synchronization is done to be as often as possible real-time (e.g. providing server push) and
also to work offline.

The methods to sync is prioritiesed in the following order:

WebSockets
SSE
HTTP
LocalStorage

    Backbone.getSyncMethod = (url) ->
        console.log "getSyncMethod"

        wsConnection = null
        listeners = []

        connect = ->
            return new Promise (resolve, reject) ->
                unless wsConnection
                    console.log "first try to connect"
                    wsConnection = new WebSocket "ws://#{window.location.host}#{url}"
                    wsConnection.onopen = ->
                        resolve wsConnection
                    wsConnection.onerror = ->
                        reject Error("websocket error")
                    wsConnection.onmessage = (msg) ->
                        newListeners = []
                        for listener in listeners
                            unless listener(msg)
                                newListeners.push listener
                        listeners = newListeners

                else if wsConnection.readyState isnt 1
                    console.log "connection not ok and appended onopen"
                    oldopen = wsConnection.onopen;
                    wsConnection.onopen = ->
                        console.log "onopen with appended listener"
                        oldopen()
                        resolve wsConnection
                else
                    console.log "connection ok"
                    resolve wsConnection

        wsMessage = (wsConnection, message) ->
            console.log "send message"
            console.log message

            return new Promise (resolve, reject) ->
                ts = Date.now() + Math.random()
                listeners.push ((resolve, ts, msg) ->
                    console.log 'received message'
                    console.log ts
                    msg = JSON.parse msg.data
                    console.log msg
                    if msg.ts is ts
                        console.log "resolve"
                        resolve msg.data
                        return true
                    else 
                        return false
                ).bind @, resolve, ts

                message.ts = ts
                wsConnection.send JSON.stringify message

        return (method, model, options) ->

            if method is "create"
                connect()
                    .then (wsConnection) ->
                        wsMessage(wsConnection, {method: "create", doc: model.attributes})
                    .then (msg) ->
                        model.set msg

            else if method is "read"
                console.log "read in sync"
                connect()
                    .then (wsConnection) ->
                        wsMessage(wsConnection, {method: "read"})
                    .then (msg) ->
                        model.set msg
                        model.trigger "sync", msg, options
                        subscribe model

            else if method is "subscribe"
                console.log "subscribe in sync"
                connect()
                    .then (wsConnection) ->
                        wsMessage wsConnection, {method: "subscribe", channel: url}
                    .then (msg) ->
                        connect()
                    .then (wsConnection) ->
                        listeners.push ((msg)->
                            console.log "subscription message"
                            console.log msg
                            ).bind @

            else 
                Backbone.ajaxSync method, model, options



Other Backbone overrides that should be moved elsewhere maybe?

    Backbone.Collection.prototype.subscribe = (options) ->
        @.sync "subscribe", @, options
