
/**
 * Module dependencies.
 */

var express = require('express'),
  	routes = require('./routes'),
  	user = require('./routes/user'),
  	http = require('http'),
  	path = require('path');

var app = express();

// all environments
app.set('port', process.env.PORT || 8080);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/', routes.index);
app.get('/users', user.list);

var io = require('socket.io').listen(app.get('port')),
	sockets = {};

io.sockets.on("connection", function(socket){

	var joinRoom = function(socket, room){
			socket.room = room;
			socket.join(room);
			socket.broadcast.to(socket.room).emit("chat:connected", socket.data);
			socket.emit("chat:users_list", getUsersWithinTheRoom(socket.room));
		},
		disconnect = function(socket) {
			socket.leave(socket.room)
			socket.broadcast.to(socket.room).emit("chat:disconnected", socket.data);	
		},
		getUsersWithinTheRoom = function(room) {
			return io.sockets.clients(room).map(function(u){ return u.data; });
		};

	socket.on("chat:login", function(user, args){
		socket.data = user;
		sockets[socket.data.name] = socket;
		joinRoom(socket, args.room);
	});

	socket.on("chat:message", function(message, args){
		var _socket = socket.broadcast.to(socket.room);
		if (args && args.to && sockets[args.to])
			_socket = sockets[args.to];
		_socket && _socket.emit("message", message, socket.data);
	});

	socket.on("chat:room", function(room){
		disconnect(socket);
		joinRoom(socket, room);
	});

	socket.on("disconnect", function(){
		disconnect(socket);
		delete sockets[socket.data.name];
	});
});
