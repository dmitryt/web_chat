var should = require("should"),
	io = require("socket.io-client"),
	app = require('express')(),
	url = "http://localhost:8080",

	options = {
		transport: ['websocket'],
		'force new connection': true
	},

	chatuser1 = {name: 'Tom'},
	chatuser2 = {name: 'Bob'},
	chatuser3 = {name: 'Den'},
	chatuser4 = {name: 'Bill'},

	client1, client2, client3, client4;

describe("Chat server", function(){
	var users = [],
		setupUsers = function(arr, args, cb) {
			var counter = arr.length;
			arr.forEach(function(data){
				var socket = io.connect(url, options);
				socket.data = data;
				users.push(socket.on("connect", function(){
					this.emit('chat:login', data, args);
					counter--;
					(counter == 0) && cb && cb();
				}));
			});
		},
		sortedUsers = function(_users){
			return _users.sort(function(a, b){
				if (a.name > b.name) return 1;
				if (a.name < b.name) return -1;
				return 0;
			});
		},
		resetUsers = function(){
			users.forEach(function(user){
				user.disconnect();
			});
			users = [];
		};

	before(resetUsers);
	afterEach(resetUsers);

	it("Should broadcast new user to all users within the room", function(done){
		var numUsers;

		setupUsers([chatuser1], {room: 'room1'}, function(){
			setupUsers([chatuser4], {room: 'room2'});
			setupUsers([chatuser2, chatuser3], {room: 'room1'});
		});
		numUsers = users.length; //the count of users within the 'room1' room

		users[0].on('chat:connected', function(user){
			numUsers++;
			var connectedUsers = [chatuser2, chatuser3].map(function(u){
				return u.name;
			});

			connectedUsers.should.include(user.name);
			if (numUsers == 3) {
				done();
			}
		});
	});

	it("Should broadcast to all users within the room, when anybody has been disconnected", function(done){
		var notifications = 0;
		setupUsers([chatuser1, chatuser2, chatuser3, chatuser4], {room: 'room1'}, function(){
			users[0].disconnect();
			users.slice(1).forEach(function(u){
				u.on("chat:disconnected", function(user){
					user.name.should.eql(chatuser1.name);
					notifications++;
					if (notifications == 3) done();
				});
			});
		});
	});

	it("Should be able to get data of all users inside the room", function(done){
		setupUsers([chatuser1, chatuser2, chatuser3], {room: 'room1'}, function(){
			setupUsers([chatuser4], {room: 'room1'});
			users[users.length - 1].on("chat:users_list", function(list){
				sortedUsers([chatuser1, chatuser2, chatuser3, chatuser4]).should.eql(sortedUsers(list));
				done();
			});
		});
	});

	it("Should be able to send messages for all users within the room", function(done){
		var message = "Hello world",
			receivedUsersNames,
			receivedMessages = 0;
		setupUsers([chatuser1, chatuser2, chatuser3], {room: 'room1'}, function(){
			setupUsers([chatuser4], {room: 'room2'}, function(){
				users[0].emit("chat:message", message);
				receivedUsersNames = [chatuser2, chatuser3].map(function(u){
					return u.name;
				});
				users.slice(1).forEach(function(user){
					user.on("message", function(_message, sender){
						receivedMessages++;
						receivedUsersNames.should.include(user.data.name);
						receivedUsersNames.splice(receivedUsersNames.indexOf(user.data.name), 1);
						sender.name.should.eql(chatuser1.name);
						_message.should.eql(message);
						if (receivedMessages == 2) {
							done();
						};
					})
				});
			});
		});
	});

	it("Should be able to send private messages to any user inside the room", function(done){
		var message = "Hello private world";
		setupUsers([chatuser1, chatuser2, chatuser3, chatuser4], {room: 'room1'}, function(){
			users[0].emit("chat:message", message, {to: chatuser2.name});
			users.forEach(function(user){
				user.on("message", function(_message, from){
					from.name.should.eql(chatuser1.name);
					user.data.name.should.eql(chatuser2.name);
					_message.should.eql(message);
					done();
				})
			});
		});
	});

	it("Should be able for any user to switch the room", function(done){
		var changedRoomUsers = [chatuser2, chatuser3].map(function(u){
			return u.name;
		}),
		 usersChangedRoomCount = 0;

		setupUsers([chatuser1, chatuser2, chatuser3, chatuser4], {room: 'room1'}, function(){
			users.forEach(function(user){
				user.on("chat:disconnected", function(data){
					changedRoomUsers.should.include(data.name);
				});
			});
			users.slice(1,3).forEach(function(user){
				user.emit("chat:room", "room2");
				user.on("chat:connected", function(){
					usersChangedRoomCount++;
					changedRoomUsers.should.include(this.data.name);
					if (usersChangedRoomCount == 2) {
						done();
					}
				});
			});
		});
	});

});
