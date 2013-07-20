
chai = require "chai"
should = chai.should()
crud = require("..")()

describe 'crud functions', () ->
	
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

			crud.create 'Test', {'value': 1, 'otherkey': true}, () ->
				crud.create 'Test', {'value': 2, 'otherkey': false}, () ->
					crud.create 'Test', {'value': 3, 'other': true}, () ->
						done()

		it 'should return documents with value 3 when query is {"value":3}', (done) ->

			crud.get 'Test', {'value': 3}, {}, (err, items) ->
				should.not.exist err
				for item in items
					item.should.have.property('value').with.eql 3
				done()

		it 'should return documents with value less then 3 when query is { "value": { $lt: 3 }}', (done) ->

			crud.get "Test", {'value': {$lt: 3}}, {}, (err, items) ->
				should.not.exist err
				for item in items
					item.should.have.property('value')
					(item.value < 3).should.be.true
				done()

		it 'should return only the amount of documents that is set in the limit option', (done) ->

			crud.get 'Test', {}, {limit: 1}, (err, items) ->
				should.not.exist err
				items.should.have.lengthOf 1

				crud.get 'Test', {}, {limit: 2}, (err, items) ->
					should.not.exist err
					items.should.have.lengthOf 2
					done()

	describe 'delete', () ->

		it 'should delete all the documents from the collection', (done) ->

			crud.get 'Test', {}, {}, (err, items) ->
				nritems = items.length

				for item in items

					crud.del 'Test', item._id.toHexString(), (err) ->

						should.not.exist err

						nritems--
						if nritems is 0

							crud.get 'Test', {}, {}, (err, items) ->
								items.should.have.length(0)
								done()


request = require "supertest"
express = require "express"
#create the application
app = express()

app.use "/testrest", crud.getApp("testrest")

describe 'crud REST interface', () ->
	
	describe 'HTTP POST / create', () ->

		it 'should create a new document', (done) ->

			request(app)
				.post("/testrest")
				.send({'hello': 'create'})
				.expect(200)
				.end (err, res) ->
					should.not.exist err
					res.body.should.have.keys 'hello', '_id'
					done()

	describe 'HTTP PUT / update', () ->

		it 'should update an existing document', (done) ->

			request(app)
				.post("/testrest")
				.send({'hello': 'upd'})
				.end (err, res) ->
					should.not.exist err
					res.body.should.have.keys '_id', 'hello'
					res.body.should.have.property 'hello', 'upd'

					request(app)
						.put("/testrest/#{res.body._id}")
						.send({'hello': 'update'})
						.expect(200)
						.end (err, res) ->
							should.not.exist err
							res.body.should.have.keys '_id', 'hello'
							res.body.should.have.property 'hello', 'update'
							done()

		it 'should return 404 not found if the document queried does not exist', (done) ->

			request(app)
				.put("/testrest/doesnotexist")
				.send({'hello': 'doesnotexist'})
				.expect(404, done)


		it 'should only update the given key value pairs', (done) ->

			request(app)
				.post("/testrest")
				.send({'hello': 'upd', 'do': 'not touch'})
				.expect(200)
				.end (err, res) ->
					should.not.exist err

					request(app)
						.put("/testrest/#{res.body._id}")
						.send({'hello': 'update'})
						.expect(200)
						.end (err, res) ->
							should.not.exist err
							res.body.should.have.keys '_id', 'hello', 'do'
							res.body.do.should.equal 'not touch'
							res.body.hello.should.equal 'update'
							done()

	describe 'HTTP GET / get', () ->

		before (done) ->
			request(app)
				.post("/testrest")
				.send({'value': 1})
				.end (err, res) ->
					request(app)
						.post("/testrest")
						.send({'value': 2})
						.end (err, res) ->
							request(app)
								.post("/testrest")
								.send({'value': 3})
								.end (err, res) ->
									done()

		it 'should return documents with value 3 when query is {"value": 3}', (done) ->

			request(app)
				.get("/testrest")
				.query({query: JSON.stringify {'value': 3}})
				.end (err, res) ->
					should.not.exist err

					for item in res.body
						item.should.have.property('value').with.eql 3

					done()

		it 'should return documents with values less then 3 when query is { "value": { $lt: 3 }}', (done) ->

			request(app)
				.get("/testrest")
				.query({query: JSON.stringify {'value': {$lt: 3}}})
				.end (err, res) ->
					should.not.exist err

					for item in res.body
						item.should.have.property('value')
						(item.value < 3).should.be.true

					done()

		it 'should return only the amount of documents that is set in the limit option', (done) ->

			request(app)
				.get("/testrest")
				.query({options: JSON.stringify {limit: 1}})
				.end (err, res) ->
					should.not.exist err
					res.body.should.have.lengthOf 1

					request(app)
						.get("/testrest")
						.query({options: JSON.stringify {limit: 2}})
						.end (err, res) ->
							should.not.exist err
							res.body.should.have.lengthOf 2
							done()

	describe 'HTTP DELETE / delete', () ->

		it 'should delete all the documents from the collection', (done) ->

			request(app)
				.get("/testrest")
				.end (err, res) ->
					nritems = res.body.length

					for item in res.body
						request(app)
							.del("/testrest/#{item._id}")
							.end (err, res) ->
								nritems--
								if nritems is 0
									request(app)
										.get("/testrest")
										.end (err, res) ->
											res.body.should.have.length 0
											done()


#set up websocket interface
server = require("http").createServer(app)
io = require("socket.io").listen(server)
io.set 'log level', 1
crud.set "/wsrest", "wstest", app, io

server.listen(3010)

describe 'cruds websocket interface', () ->

	socket = null

	it 'should be able to connect', (done) ->

		ioclient = require 'socket.io-client'
		socket = ioclient.connect 'http://localhost:3010/wsrest'

		socket.once 'connect', () ->
			socket.socket.connected.should.be.true
			done()


	describe 'create', () ->

		it 'should create a new document', (done) ->

			socket.emit 'create', {'hello': 'create'}

			socket.once 'create', (data) ->
				data.should.have.keys '_id', 'hello'
				done()

	describe 'update', () ->

		it 'should update an existing document', (done) ->

			socket.emit 'create', {'hello': 'upd'}

			socket.once 'create', (data) ->
				data.should.have.keys '_id', 'hello'

				socket.emit 'update', {'hello': 'update', '_id': data._id}

				socket.once 'update', (data) ->
					data.should.have.keys '_id', 'hello'
					data.should.have.property 'hello', 'update'
					done()

	describe 'get', () ->

		before (done) ->

			socket.emit 'create', {'value': 1}

			socket.once 'create', (data) ->
				data.should.have.keys '_id', 'value'

				socket.emit 'create', {'value': 2}

				socket.once 'create', (data) ->
					data.should.have.keys '_id', 'value'

					socket.emit 'create', {'value': 3}

					socket.once 'create', (data) ->
						data.should.have.keys '_id', 'value'
						done()


		it 'should return documents with value 3 when query is {"value": 3}', (done) ->

			socket.emit 'get', {query: {value: 3}}

			socket.once 'get', (data) ->
				for item in data
					item.should.have.property('value').with.eql 3

				done()

	describe 'delete', () ->

		it 'should delete all the documents from the collection', (done) ->

			socket.emit 'get', {}

			socket.once 'get', (data) ->
				nritems = data.length

				socket.on 'delete', () ->
					nritems--
					if nritems is 0

						socket.emit 'get', {}

						socket.on 'get', (data) ->
							data.should.have.length 0
							done()

				for item in data
					socket.emit 'delete', {_id: item._id}






						




