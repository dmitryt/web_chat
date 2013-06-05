
#
# Module dependencies.
#

express = require('express')
http = require('http')
path = require('path')

app = express()

# all environments
app.set('port', process.env.PORT || 8080)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon())
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))

# development only

app.use(express.errorHandler()) if 'development' == app.get('env')

io = require('socket.io').listen(app.get('port'))
sockets = {}

io.sockets.on "connection", (socket) ->

	joinRoom = (socket, room) ->
		socket.room = room
		socket.join(room)
		socket.broadcast.to(socket.room).emit("chat:connected", socket.data)
		socket.emit("chat:users_list", getUsersWithinTheRoom(socket.room))

	disconnect = (socket) ->
		socket.leave(socket.room)
		socket.broadcast.to(socket.room).emit("chat:disconnected", socket.data)

	getUsersWithinTheRoom = (room) ->
		io.sockets.clients(room).map (u) ->
			u.data

	socket.on "chat:login", (user, args) ->
		socket.data = user
		sockets[socket.data.name] = socket
		joinRoom(socket, args.room)

	socket.on "chat:message", (message, args) ->
		_socket = socket.broadcast.to(socket.room)
		_socket = sockets[args.to] if (args && args.to && sockets[args.to])
		_socket.emit("message", message, socket.data) if _socket

	socket.on "chat:room", (room) ->
		disconnect(socket)
		joinRoom(socket, room)

	socket.on "disconnect", ->
		disconnect(socket)
		delete sockets[socket.data.name]
