
chai = require "chai"
should = chai.should()
mongoose = require "mongoose"
cruds = require "../../lib/cruds"

Entity = cruds {
	connectionString: "mongodb://localhost:27017/test"
}
SchemaEntity = cruds {
	name: "Person"
	connectionString: "mongodb://localhost:27017/test"
	schema: new mongoose.Schema {name: String}
}

describe 'crud functions',  ->
	
	describe 'create',  ->

		it 'should create a new document in schemaless CRUDS', (done) ->		
			Entity.exists {'hello': 'world'}, (err, bool) ->
				bool.should.be.false
				Entity.create {'hello': 'world'}, (err, doc) ->
					doc.should.have.keys '_id'
					Entity.exists doc, (err, bool) ->
						bool.should.be.true
						done()

	describe 'update',  ->

		it 'should update an existing document', (done) ->
			Entity.get {}, null, null, (err, docs) ->
				doc = docs[0].toObject()
				Entity.update doc._id, {$set: {updated: true}}, (err, numberAffected, raw) ->
					should.not.exist err
					numberAffected.should.equal 1
					done()

	describe 'get',  ->

		before (done) ->
			Entity.create {value: 1}, (err, doc) ->
				Entity.create {value: 3}, (err, doc) ->
					done()

		it 'should return documents with value 3 when query is {"value":3}', (done) ->
			Entity.get {"value": 3}, null, null, (err, docs) ->
				for doc in docs
					obj = doc.toObject()
					should.exist obj.value
					obj.value.should.equal 3
				done()	

		it 'should return documents with value less then 3 when query is { "value": { $lt: 3 }}', (done) ->
			Entity.get { "value": { $lt: 3 }}, null, null, (err, docs) ->
				for doc in docs
					obj = doc.toObject()
					should.exist obj.value
					(obj.value < 3).should.equal true
				done()	

		it 'should return only the amount of documents that is set in the limit option', (done) ->
			Entity.get {}, null, {limit: 1}, (err, docs) ->
				(docs.length).should.equal 1
				done()	


	describe 'delete',  ->

		it 'should delete all the documents from the collection', (done) ->
			Entity.get {}, null, null, (err, docs) ->
				i = 0 
				for doc in docs
					Entity.del doc._id, (err) ->
						i++
						if i is docs.length
							Entity.get {}, null, null, (err, docs) ->
								done()	
