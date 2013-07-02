

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

	describe 'get', () ->

		before (done) ->

			crud.create 'Test', {'value': 1}, () ->
				crud.create 'Test', {'value': 2}, () ->
					crud.create 'Test', {'value': 3}, () ->
						done()

		it 'should return documents with value 3 when query is {"value":3}', (done) ->

			crud.get 'Test', {'value': 3}, (err, items) ->
				should.not.exist err
				for item in items
					item.should.have.property('value').with.eql 3
				done()

		it 'should return documents with value less then 3 when query is { "value": { $lt: 3 }}', (done) ->

			crud.get "Test", {'value': {$lt: 3}}, (err, items) ->
				should.not.exist err
				for item in items
					item.should.have.property('value').with.not.eql 3
				done()

	describe 'delete', () ->

		it 'should delete all the documents from the collection', (done) ->

			crud.get 'Test', {}, (err, items) ->
				nritems = items.length

				for item in items

					crud.delete 'Test', item._id.toHexString(), (err) ->

						should.not.exist err

						nritems--
						if nritems is 0

							crud.get 'Test', {}, (err, items) ->
								items.should.have.length(0)
								done()

