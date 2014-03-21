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

        wsConnection = null
        listeners = []

        connect = ->

            return new Promise (resolve, reject) ->
                
                unless wsConnection?
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

                else if wsConnection? and wsConnection.readyState isnt 1
                    oldopen = wsConnection.onopen;
                    wsConnection.onopen = ->
                        oldopen()
                        resolve wsConnection
                else
                    resolve wsConnection

        wsMessage = (wsConnection, message) ->

            return new Promise (resolve, reject) ->
                ts = Date.now() + Math.random()
                listeners.push ((resolve, ts, msg) ->
                    msg = JSON.parse msg.data
                    if msg.ts is ts
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
                        model.trigger "sync", model, msg, options

                        if options.broadcast
                            connect()
                                .then (wsConnection) ->
                                    wsMessage wsConnection, {method: "broadcast", data: model.attributes, channel: url}

            else if method is "read"
                connect()
                    .then (wsConnection) ->
                        wsMessage(wsConnection, {method: "read"})
                    .then (msg) ->
                        model.set msg
                        model.trigger "sync", model, msg, options
                        subscribe model

            else if method is "subscribe"
                connect()
                    .then (wsConnection) ->
                        wsMessage wsConnection, {method: "subscribe", channel: url}
                    .then (msg) ->
                        connect()
                    .then (wsConnection) ->
                        listeners.push ((msg)->
                            data = JSON.parse msg.data
                            if data.channel is url
                                m = model.get(data.data._id)
                                if m
                                    m.set data.data
                                else
                                    model.create data.data
                            ).bind @

            else if method is "upload"

                formdata = new FormData()
                formdata.append "file", options.file, options.fileName

                oReq = new XMLHttpRequest()
                oReq.onload = ->
                    response = JSON.parse @responseText
                    model.set {"file": response.file}                    
                    model.trigger "sync", model, response, options

                oReq.open("PUT", "#{url}/#{model.id}")
                oReq.send formdata

Backbone.ajaxSync method, model, options

            else 
                Backbone.ajaxSync method, model, options



Other Backbone overrides that should be moved elsewhere maybe?

    Backbone.Collection.prototype.subscribe = (options) ->
        @sync "subscribe", @, options

    Backbone.Model.prototype.upload = (options) ->
        @sync "upload", @, options

