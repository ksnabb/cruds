should = chai.should();
ws = null

# globals for testing (remove them when time allows)
fileId = null

wsMessage = (message, answer) ->
    ws.onmessage = answer
    ws.send JSON.stringify message

describe 'CRUDS',  ->

    before (done) ->
        ws = new WebSocket 'ws://localhost:3000/entity'
        ws.onopen = ->
            done()

    
    describe 'HTTP POST', ->

        it 'should create a new document', (done) ->
            $.ajax
                method: "POST"
                url: "/entity"
                data: {'hello': 'world'}
                success: (data) ->
                    data.should.have.keys('_id')
                complete: (data, status) ->
                    status.should.equal "success"
                    done()

        it 'should be able to create documents with files', (done) ->
            file = new Blob(["this is a plain text file"], {type: "text/plain"})

            formdata = new FormData()
            formdata.append "name-of-file-field", file, "name.txt"
            formdata.append "other", "value"
            
            oReq = new XMLHttpRequest()
            oReq.onload = ->
                response = JSON.parse this.responseText
                response.should.have.keys('_id')
                fileId = response._id
                done()

            oReq.open("POST", "/entity")
            oReq.send formdata

    describe 'HTTP GET', ->

        it 'should return documents', (done) ->

            $.ajax
                method: "GET"
                url: "/entity"
                success: (data) ->
                    data.length.should.not.eql 0
                complete: (data, status) ->
                    status.should.equal "success"
                    done()

        it 'should return one document according to its URI', (done) ->

            $.ajax
                method: "GET"
                url: "/entity/#{fileId}"
                success: (data) ->
                    data.length.should.eql 1
                complete: (data, status) ->
                    status.should.equal "success"
                    done()

        it 'should be able to retrieve files attached to a document', (done) ->

            $.ajax
                method: "GET"
                url: "/entity/#{fileId}"
                success: (data) ->
                    $.ajax
                        method: "GET"
                        url: "/entity/file/#{data[0]["name-of-file-field"].id}"
                        success: (data) ->
                            done()

    describe 'HTTP PUT', ->

        it 'should update a document', (done) ->
            $.ajax
                method: "GET"
                url: "/entity"
                success: (data) ->
                    id = data[0]._id
                    $.ajax
                        method: "PUT"
                        url: "/entity/#{id}"
                        data: {'updated': true}
                        complete: (data, status) ->
                            status.should.equal "success"
                            done()
                error: ->
                    true.should.be.false
                    done()
                complete: (data, status) ->
                    status.should.equal "success"

        it 'should be able to update files in documents', (done) ->

            file = new Blob ["this is a plain text file with updates"], {type: "text/plain"}

            formdata = new FormData()
            formdata.append "name-of-file-field", file, "name.txt"
            formdata.append "other", "value"
            
            oReq = new XMLHttpRequest()
            oReq.onload = ->
                response = JSON.parse this.responseText
                oReq = new XMLHttpRequest()
                oReq.onload = ->
                    response = JSON.parse this.responseText

                    oReq = new XMLHttpRequest()
                    oReq.onload = ->
                        unless window.mochaPhantomJS # TODO find a way to test this in phantomjs
                            this.responseText.should.eql "this is a plain text file with updates"
                        done()

                    oReq.open("GET", "/entity/file/#{response[0]['name-of-file-field'].id}")
                    oReq.send()

                oReq.open("GET", "/entity/#{fileId}")
                oReq.send()

            oReq.open("PUT", "/entity/#{fileId}")
            oReq.send formdata


    describe 'HTTP DELETE', ->

        it 'should delete a document', (done) ->    
            $.ajax
                method: "GET"
                url: "/entity"
                success: (data) ->
                    id = data[0]._id
                    $.ajax
                        method: "DELETE"
                        url: "/entity/#{id}"
                        complete: (data, status) ->
                            status.should.equal "success"
                            done()
                error: ->
                    true.should.be.false
                    done()
                complete: (data, status) ->
                    status.should.equal "success"

    describe 'read with WebSockets', ->

        it 'should return some documents', (done) ->
            wsMessage {method: 'read', query: {}}, (evt) ->
                obj = JSON.parse evt.data
                (obj.length > 0).should.be.true
                done()

    describe 'create with WebSockets', ->

        it 'should create a document', (done) ->

            wsMessage {method: 'create', doc: {hello: 'worlds'}}, (evt) ->
                obj = JSON.parse evt.data
                obj.should.have.keys '_id'
                id = obj._id

                wsMessage {method: 'read', query: {'_id': id}}, (evt) ->
                    obj = JSON.parse evt.data
                    obj[0]._id.should.eql id
                    obj[0].hello.should.eql "worlds"
                    done()
    
    describe 'update with WebSockets', ->

        it 'should update a document', (done) ->

            wsMessage {method: 'read', query: {}}, (evt) ->
                obj = JSON.parse evt.data

                wsMessage {method: 'update', id: obj[0]._id, doc: {$set: {updated: true}}}, (evt) ->
                    evt.data.should.eql "{}"
                    done()

    
    describe 'delete with WebSockets', ->

        it 'should delete a document', (done) ->
            wsMessage {method: 'read', query: {}}, (evt) ->
                obj = JSON.parse evt.data

                wsMessage {method: 'delete', id: obj[0]._id}, (evt) ->
                    evt.data.should.eql "null"
                    done()

    describe 'subscribe with WebSockets', ->

        it 'should be able to subscribe to channels and receive updates from all other sockets subscribed to that channel', (done) ->

            wsMessage {method: "subscribe", channel: 'channel-13'}, (evt) ->
                evt.data.should.eql "{}"

                wsMessage {method: "subscriptions"}, (evt) ->
                    evt.data.should.include "channel-13"
                    done()

    describe 'unsubscribe with WebSockets', ->

        it 'should be able to unsubscribe to previously subscribed channels', (done) ->

            wsMessage {method: "unsubscribe", channel: 'channel-13'}, (evt) ->
                evt.data.should.eql "{}"

                wsMessage {method: "subscriptions"}, (evt) ->
                    evt.data.should.not.include "channel-13"
                    done()

    describe 'subscribe with long poll', ->

        it 'should respond when there is an update'

    describe 'subscribe with SSE', ->

        it 'should respond when there is an update'

