
chai = require "chai"
should = chai.should()
cruds = require("..")()
entity = new cruds.Entity("Test")

describe 'crud functions',  ->
	
	describe 'create',  ->

		it 'should create a new document', (done) ->

			entity.create {'hello': 'create'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello'
				done()

	describe 'update',  ->

		it 'should update an existing document', (done) ->

			entity.create {'hello': 'upd'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello'

				entity.update col._id.toHexString(), {'hello': 'update'}, (err, count) ->
					should.not.exist err
					count.should.equal 1
					done()

		it 'should return count 0 for updated documents if the document queried does not exist', (done) ->

			entity.update 'noidwith12bi', {'hello', 'does not exist'}, (err, count) ->
					should.not.exist err
					count.should.equal 0
					done()

		it 'should only update the given key value pairs', (done) ->

			entity.create {'hello': 'upd', 'do': 'not touch'}, (err, col) ->
				should.not.exist err
				col.should.have.keys '_id', 'hello', 'do'

				entity.update col._id.toHexString(), {'hello': 'update'}, (err, count) ->
					should.not.exist err
					count.should.equal 1

					entity.getById col._id.toHexString(), (err, item) ->
						should.not.exist err
						item.should.have.keys '_id', 'hello', 'do'
						item.do.should.equal 'not touch'
						item.hello.should.equal 'update'
						done()

	describe 'get',  ->

		before (done) ->

			entity.create {'value': 1, 'otherkey': true},  ->
				entity.create {'value': 2, 'otherkey': false},  ->
					entity.create {'value': 3, 'other': true},  ->
						done()

		it 'should return documents with value 3 when query is {"value":3}', (done) ->

			entity.get {'value': 3}, {}, (err, items) ->
				should.not.exist err
				for item in items
					item.should.have.property('value').with.eql 3
				done()

		it 'should return documents with value less then 3 when query is { "value": { $lt: 3 }}', (done) ->

			entity.get {'value': {$lt: 3}}, {}, (err, items) ->
				should.not.exist err
				for item in items
					item.should.have.property('value')
					(item.value < 3).should.be.true
				done()

		it 'should return only the amount of documents that is set in the limit option', (done) ->

			entity.get {}, {limit: 1}, (err, items) ->
				should.not.exist err
				items.should.have.lengthOf 1

				entity.get {}, {limit: 2}, (err, items) ->
					should.not.exist err
					items.should.have.lengthOf 2
					done()

	describe 'delete',  ->

		it 'should delete all the documents from the collection', (done) ->

			entity.get {}, {}, (err, items) ->
				nritems = items.length

				for item in items

					entity.del item._id.toHexString(), (err) ->

						should.not.exist err

						nritems--
						if nritems is 0

							entity.get {}, {}, (err, items) ->
								items.should.have.length(0)
								done()


request = require "supertest"
express = require "express"
#create the application
app = express()
cruds.set("Test", app)

describe 'cruds REST interface',  ->
	
	describe 'HTTP POST / create',  ->

		it 'should create a new document', (done) ->

			request(app)
				.post("/test")
				.send({'hello': 'create'})
				.expect(200)
				.end (err, res) ->
					should.not.exist err
					res.body.should.have.keys 'hello', '_id'
					done()

	describe 'HTTP PUT / update',  ->

		it 'should update an existing document', (done) ->

			request(app)
				.post("/test")
				.send({'hello': 'upd'})
				.end (err, res) ->
					should.not.exist err
					res.body.should.have.keys '_id', 'hello'
					res.body.should.have.property 'hello', 'upd'

					request(app)
						.put("/test/#{res.body._id}")
						.send({'hello': 'update'})
						.expect(200)
						.end (err, res) ->
							should.not.exist err
							res.body.should.have.keys '_id', 'hello'
							res.body.should.have.property 'hello', 'update'
							done()

		it 'should return 404 not found if the document queried does not exist', (done) ->

			request(app)
				.put("/test/doesnotexist")
				.send({'hello': 'doesnotexist'})
				.expect(404, done)


		it 'should only update the given key value pairs', (done) ->

			request(app)
				.post("/test")
				.send({'hello': 'upd', 'do': 'not touch'})
				.expect(200)
				.end (err, res) ->
					should.not.exist err

					request(app)
						.put("/test/#{res.body._id}")
						.send({'hello': 'update'})
						.expect(200)
						.end (err, res) ->
							should.not.exist err
							res.body.should.have.keys '_id', 'hello', 'do'
							res.body.do.should.equal 'not touch'
							res.body.hello.should.equal 'update'
							done()

	describe 'HTTP GET / get',  ->

		before (done) ->
			request(app)
				.post("/test")
				.send({'value': 1})
				.end (err, res) ->
					request(app)
						.post("/test")
						.send({'value': 2})
						.end (err, res) ->
							request(app)
								.post("/test")
								.send({'value': 3})
								.end (err, res) ->
									done()

		it 'should return documents with value 3 when query is {"value": 3}', (done) ->

			request(app)
				.get("/test")
				.query({query: JSON.stringify {'value': 3}})
				.end (err, res) ->
					should.not.exist err

					for item in res.body
						item.should.have.property('value').with.eql 3

					done()

		it 'should return documents with values less then 3 when query is { "value": { $lt: 3 }}', (done) ->

			request(app)
				.get("/test")
				.query({query: JSON.stringify {'value': {$lt: 3}}})
				.end (err, res) ->
					should.not.exist err

					for item in res.body
						item.should.have.property('value')
						(item.value < 3).should.be.true

					done()

		it 'should return only the amount of documents that is set in the limit option', (done) ->

			request(app)
				.get("/test")
				.query({options: JSON.stringify {limit: 1}})
				.end (err, res) ->
					should.not.exist err
					res.body.should.have.lengthOf 1

					request(app)
						.get("/test")
						.query({options: JSON.stringify {limit: 2}})
						.end (err, res) ->
							should.not.exist err
							res.body.should.have.lengthOf 2
							done()

	describe 'HTTP DELETE / delete',  ->

		it 'should delete all the documents from the collection', (done) ->

			request(app)
				.get("/test")
				.end (err, res) ->
					nritems = res.body.length

					for item in res.body
						request(app)
							.del("/test/#{item._id}")
							.end (err, res) ->
								nritems--
								if nritems is 0
									request(app)
										.get("/test")
										.end (err, res) ->
											res.body.should.have.length 0
											done()


#set up websocket interface
server = require("http").createServer(app)
io = require("socket.io").listen server
io.set 'log level', 0
namespace = "wsrest"
cruds.set namespace, null, io

server.listen(3010)

ioclient = require 'socket.io-client'
socket = socket2 = null	
socket = ioclient.connect "http://localhost:3010/#{namespace}"

describe 'cruds websocket interface', ->

	describe 'create', ->

		it 'should create a new document', (done) ->

			socket.once 'create', (data) ->
				data.should.have.keys '_id', 'hello'
				done()

			socket.emit 'create', {'hello': 'create'}

	describe 'update',  ->

		it 'should update an existing document', (done) ->

			socket.emit 'create', {'hello': 'upd'}

			socket.once 'create', (data) ->
				data.should.have.keys '_id', 'hello'

				socket.emit 'update', {'hello': 'update', '_id': data._id}

				socket.once 'update', (data) ->
					data.should.have.keys '_id', 'hello'
					data.should.have.property 'hello', 'update'
					done()

	describe 'get',  ->

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

	describe 'subscribe & unsubscribe',  ->

		before (done) ->
			socket2 = ioclient.connect "http://127.0.0.1:3010/#{namespace}"
			socket2.once 'connect',  ->
				done()

		beforeEach  ->
			socket.socket.connected.should.be.true
			socket2.socket.connected.should.be.true

		query = {value: 3}

		it 'should be able to subscribe to a query', (done) ->

			socket2.once 'subscribed',  ->

				socket2.once 'rooms', (rooms) ->
					rooms.should.have.property "/#{namespace}/#{JSON.stringify query}"
					done()

				socket2.emit 'rooms', ''

			socket2.emit 'subscribe', query

		it 'should receive creates for the subscribed query', (done) ->

			socket2.once 'create', (data) ->
				data.should.have.keys 'value', '_id', 'to', 'from'
				data.should.have.property 'value', 3
				data.should.have.property 'from', 1
				done()

			socket.emit 'create', {value: 3, from: 1, to: 2}

		it 'should receive updates for the subscribed query', (done) ->

			socket2.once 'update', (data) ->
				data.should.have.property 'update', 'update'
				done()

			socket.once 'create', (data) ->
				data.update = 'update'
				socket.emit 'update', data


			socket.emit 'create', {value: 3, 'update': 'upd'}
			

		it 'should be able to unsubscribe from a query', (done) ->

			socket2.once 'unsubscribed',  ->

				socket2.once 'rooms', (rooms) ->
					rooms.should.have.keys "", "/#{namespace}"
					done()

				socket2.emit 'rooms', ''

			socket2.emit 'unsubscribe', query

		it 'should be able to create a duplex connection between client sockets', (done) ->

			socket.once 'subscribed', ->

				socket2.once 'subscribed', ->

					socket2.once 'create', (data) ->
						data.should.have.property 'to', 'socket2'
						data.should.have.property 'from', 'socket'

						socket.once 'create', (data) ->
							data.should.have.property 'to', 'socket'
							data.should.have.property 'from', 'socket2'

							done()

						socket2.emit 'create', {from: 'socket2', to: 'socket'}

					socket.emit 'create', {from: 'socket', to: 'socket2'}

				socket2.emit 'subscribe', {to: 'socket2'}

			socket.emit 'subscribe', {to: 'socket'}


	describe 'delete',  ->

		it 'should delete all the documents from the collection one at the time', (done) ->

			socket.emit 'get', {}

			socket.once 'get', (data) ->
				nritems = data.length

				socket.on 'delete',  ->
					nritems--
					if nritems is 0

						socket.emit 'get', {}

						socket.on 'get', (data) ->
							data.should.have.length 0
							done()

				for item in data
					socket.emit 'delete', {_id: item._id}







						




