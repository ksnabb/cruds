should = chai.should();

describe 'CRUDS',  ->
    
    describe 'HTTP POST', ->

        it 'should create a new document', (done) ->
            $.ajax
                method: "POST"
                url: "/entity"
                success: ->
                    console.log 'ok'
                error: ->
                    console.log 'error'
                complete: ->
                    done()

    describe 'HTTP GET', ->

        it 'should return documents'

    describe 'HTTP PUT', ->

        it 'should update a document'

    describe 'HTTP DELETE', ->

        it 'should delete a document'

    describe 'subscribe with long poll', ->

        it 'should respond when there is an update'

    describe 'subscribe with SSE', ->

        it 'should respond when there is an update'

    describe 'create with WebSockets', ->

        it 'should create a documnet'

    describe 'read with WebSockets', ->

        it 'should return some documents'
    
    describe 'update with WebSockets', ->

        it 'should update a document'
    
    describe 'delete with WebSockets', ->

        it 'should delete a document'

    describe 'subscribe with WebSockets', ->

        it 'should subscribe to updates of documents'
