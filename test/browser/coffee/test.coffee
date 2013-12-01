should = chai.should();

describe 'CRUDS',  ->
    
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

        it 'should be able to create documents with files'

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

    describe 'create with WebSockets', ->

        it 'should create a document', (done) ->
            ws = new WebSocket 'ws://localhost:3000/entity'
            ws.onopen = ->

                ws.onmessage = (evt) ->
                    obj = JSON.parse evt.data
                    obj.should.have.keys '_id'
                    done()

                ws.send JSON.stringify {method: 'create', data: {hello: 'world'}}

    describe 'read with WebSockets', ->

        it 'should return some documents'
    
    describe 'update with WebSockets', ->

        it 'should update a document'
    
    describe 'delete with WebSockets', ->

        it 'should delete a document'

    describe 'subscribe with WebSockets', ->

        it 'should subscribe to updates of documents'

    describe 'subscribe with long poll', ->

        it 'should respond when there is an update'

    describe 'subscribe with SSE', ->

        it 'should respond when there is an update'
