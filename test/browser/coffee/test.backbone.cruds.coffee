should = chai.should();

###
The backbone Sync should have been replace when the sync method was loaded
###
sync = Backbone.getSyncMethod('/entity')
Model = Backbone.Model.extend {
    sync: sync
    idAttribute: "_id"
}
Collection = Backbone.Collection.extend {
    model: Model
    url: '/entity'
    sync: sync
}
collection = new Collection()

# inject iframe into page to be used as the other client for the server
# this is for testing peer to peer communications through the cruds server
iframe = document.createElement "iframe"
iframe.src = "iframe.html"
port = null

describe "Sync", ->

    before (done) ->
        # Check that the iframe has loaded and responds to messages
        handleMessage = (evt) ->
            if evt.data is "hello"
                port = evt.ports[0]   
                window.removeEventListener "message", handleMessage
                done()

        window.addEventListener "message", handleMessage, false
        $("body").append iframe

        
    it "should create new models and other clients should receive updates", (done) ->
        sayfred_id = 0
        
        # message should be reveived from the iframe
        handleMessage = (evt) ->
            if evt.data._id is sayfred_id 
                done()
        
        port.onmessage = handleMessage

        # create a new model and wait for the ID to arrive
        sayfred = collection.create {
            say: "My name is Fred!"
        }, {broadcast: true}
        sayfred.on 'change', (evt) ->
            sayfred_id = evt.changed._id

    it "should create new entities with files", (done) ->
        ###
        First a model needs to be created and saved. After it has
        gained an ID it is possible to upload it to the server.
        ###
        file = new Blob ["this is just a plain text file"], {type: "text/plain"}

        collection.once "sync", (model, collection, options) ->

            # wait for the sync
            model.on "change", (model, options) ->
                should.exist model.attributes.file
                done()

            # upload the file that will be attached to the created model
            model.upload {"file": file, "fileName": "file.txt"}            

        model = collection.create {}



        


