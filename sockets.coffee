exports.init = (server) ->
	io = require('socket.io').listen(server)

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
	false