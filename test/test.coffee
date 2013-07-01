

should = require "should"
crud = require("..")()

describe 'crud', () ->
	
	describe 'create', () ->

		it 'should create a new document', (done) ->

			crud.create 'Test', {'hello': 'create'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello'
				done()

	describe 'update', () ->

		it 'should update an existing document', (done) ->

			crud.create 'Test', {'hello': 'upd'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello'

				crud.update 'Test', col._id.toHexString(), {'hello': 'update'}, (err, count) ->
					should.not.exist err
					count.should.equal 1
					done()

		it 'should return count 0 for updated documents if the document queried does not exist', (done) ->

			crud.update 'Test', 'noidwith12bi', {'hello', 'does not exist'}, (err, count) ->
					should.not.exist err
					count.should.equal 0
					done()

		it 'should only update the given key value pairs', (done) ->

			crud.create 'Test', {'hello': 'upd', 'do': 'not touch'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello', 'do'

				crud.update 'Test', col._id.toHexString(), {'hello': 'update'}, (err, count) ->
					should.not.exist err
					count.should.equal 1

					crud.getById 'Test', col._id.toHexString(), (err, item) ->
						should.not.exist err
						item.should.have.keys '_id', 'hello', 'do'
						item.do.should.equal 'not touch'
						item.hello.should.equal 'update'
						done()
	

