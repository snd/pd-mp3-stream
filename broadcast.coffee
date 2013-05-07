net = require 'net'
http = require 'http'

pureData = null

inputServer = net.createServer (c) ->
    console.log 'pure data connected'

    if pureData?
        console.log 'pure data already connected - closing connection'
        c.destroy()
        return

    pureData = c

    pureData.on 'end', ->
        console.log 'pure data disconnected'
        pureData.removeAllListeners()
        pureData = null

inputServer.listen 9091, ->
    console.log 'listening on port 9091 and waiting for pure data to connect'

connections = 0

outputServer = http.createServer (req, res) ->
    unless pureData?
        console.log 'pure data is not connected - closing connection'
        res.writeHead 404
        res.end 'pure data is not connected'
        return

    connections = connections + 1

    console.log "browser connected. #{connections} connected"

    # res.writeHead 200
    res.writeHead 200,
        'Content-Type': 'audio/mp3'
        'Transfer-Encoding': 'chunked'

    onData = (data) ->
        res.write(data)

    onEnd = ->
        console.log 'pure data disconnected'
        req.end()

    pureData.on 'data', onData

    req.on 'close', ->
        connections = connections - 1
        if pureData?
            console.log "browser disconnected. #{connections} connected"
            pureData.removeListener 'data', onData
            pureData.removeListener 'end', onEnd

outputServer.listen 9092, ->
    console.log 'listening on port 9092 and waiting for browsers to connect'
