

should = require "should"
crud = require("..")()

describe 'crud', () ->
	
	describe 'create', () ->

		it 'should create a new document', (done) ->

			crud.create 'Test', {'hello': 'world'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello'
				done()

