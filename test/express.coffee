###
Simple test server 
###
express = require "express"
http = require "http"
path = require "path"
app = express()

app.set "port", process.env.PORT or 3000
app.use express.logger('dev')
app.use express.static(path.join(__dirname, "browser")) # test files
app.get "/", (req, res) ->
	res.redirect("/test.html")

server = http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")

#CRUDS SETUP
cruds = require("../lib/cruds")({'server': server, 'name': 'entity'})
app.use cruds.app