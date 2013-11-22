
chai = require "chai"
should = chai.should()

describe 'crud functions',  ->
	
	describe 'create',  ->

		it 'should create a new document'

	describe 'update',  ->

		it 'should update an existing document'

		it 'should only update the given key value pairs'

	describe 'get',  ->

		it 'should return documents with value 3 when query is {"value":3}'

		it 'should return documents with value less then 3 when query is { "value": { $lt: 3 }}'

		it 'should return only the amount of documents that is set in the limit option'

	describe 'delete',  ->

		it 'should delete all the documents from the collection'
