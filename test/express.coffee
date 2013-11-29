
###
Simple test server 
###
express = require "express"
http = require "http"
path = require "path"
app = express()

app.set "port", process.env.PORT or 3000
app.use express.urlencoded()
app.use express.json()
app.use express.static(path.join(__dirname, "browser"))

#CRUDS SETUP
cruds = require("../lib/cruds")()
app.use '/entity', cruds.route
app.use '/entity/:id', cruds.route

http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")


