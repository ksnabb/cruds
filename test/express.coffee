###
Simple test server 
###
express = require "express"
http = require "http"
path = require "path"
app = express()

app.set "port", process.env.PORT or 3000
app.use express.logger('dev')
app.use express.urlencoded()
app.use express.json()
app.use express.static(path.join(__dirname, "browser"))

server = http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")

#CRUDS SETUP
cruds = require("../lib/cruds")({'server': server, 'name': 'entity'})
app.use '/entity-uploads', express.static(path.join(__dirname, "../uploads/Entity")) # this is the default upload dir
app.all '/entity/:id', cruds.route
app.all '/entity', cruds.route


