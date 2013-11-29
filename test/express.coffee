
###
Simple test server 
###
express = require "express"
http = require "http"
path = require "path"
app = express()

app.set "port", process.env.PORT or 3000
app.use express.logger("dev")
app.use express.errorHandler()
app.use express.static(path.join(__dirname, "browser"))

#CRUDS SETUP
cruds = require("../lib/cruds")()
app.use '/entity', cruds.route

http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")


