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

	numUsers = 0,

	client1, client2;

describe("Chat server", function(){
	it("Should broadcast new user to all users", function(done){
		var connect = function(){
				return io.connect(url, options);
			};

		(client1 = connect()).on("connect", function(data){
			client1.emit('chat:login', chatuser1);
			
			(client2 = connect()).on("connect", function(data){
				client2.emit('chat:login', chatuser2);
			});

			client2.on('chat:connected', function(user){
				console.log('lololo');
				console.log(user);
				user.name.should.equal(chatuser1.name);	
				client2.disconnect();
			})
		});

		numUsers = 0;

		client1.on('chat:connected', function(user){
			numUsers++;

			if (numUsers == 2) {
				user.name.should.equal(chatuser2.name);
				client1.disconnect();
				done();
			}
		});
	});
});
