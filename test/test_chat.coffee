should = require("should")
io = require("socket.io-client")
app = require('express')()
url = "http://localhost:8080"

options =
	transport: ['websocket']
	'force new connection': true

chatuser1 =
	name: 'Tom'
chatuser2 =
	name: 'Bob'
chatuser3 =
	name: 'Den'
chatuser4 =
	name: 'Bill'

describe "Chat server", ->
	users = []
	setupUsers = (arr, args, cb) ->
		counter = arr.length
		arr.forEach (data) ->
			socket = io.connect(url, options)
			socket.data = data
			users.push(socket.on "connect", ->
				@emit 'chat:login', data, args
				counter--
				cb() if	counter is 0 and cb
			)

	sortedUsers = (_users) ->
		_users.sort (a, b) ->
			return 1 if a.name > b.name
			return -1 if a.name < b.name
			return 0

	resetUsers = ->
		users.forEach (user) ->
			user.disconnect()
		users = []

	before(resetUsers)
	afterEach(resetUsers)


	it "Should broadcast new user to all users within the room", (done) ->

		setupUsers [chatuser1], {room: 'room1'}, ->
			setupUsers [chatuser4], {room: 'room2'}
			setupUsers [chatuser2, chatuser3], {room: 'room1'}


		numUsers = users.length #the count of users within the 'room1' room

		users[0].on 'chat:connected', (user) ->
			numUsers++
			connectedUsers = [chatuser2, chatuser3].map	(u) ->
				u.name

			connectedUsers.should.include(user.name)
			done() if numUsers is 3
		false

	it "Should broadcast to all users within the room, when anybody has been disconnected", (done) ->
		notifications = 0;
		setupUsers [chatuser1, chatuser2, chatuser3, chatuser4], {room: 'room1'}, ->
			users[0].disconnect();
			users.slice(1).forEach (u) ->
				u.on "chat:disconnected", (user) ->
					user.name.should.eql chatuser1.name
					notifications++
					done() if notifications is 3
		false

	it "Should be able to get data of all users inside the room", (done) ->
		setupUsers [chatuser1, chatuser2, chatuser3], {room: 'room1'}, ->
			setupUsers [chatuser4], {room: 'room1'}
			users[users.length - 1].on "chat:users_list", (list) ->
				sortedUsers([chatuser1, chatuser2, chatuser3, chatuser4]).should.eql(sortedUsers(list))
				done()
		false

	it "Should be able to send messages for all users within the room", (done) ->
		message = "Hello world"
		receivedMessages = 0

		setupUsers [chatuser1, chatuser2, chatuser3], {room: 'room1'}, ->
			setupUsers [chatuser4], {room: 'room2'}, ->
				users[0].emit "chat:message", message
				receivedUsersNames = [chatuser2, chatuser3].map (u) ->
					u.name

				users.slice(1).forEach (user) ->
					user.on "message", (_message, sender) ->
						receivedMessages++
						receivedUsersNames.should.include(user.data.name)
						receivedUsersNames.splice(receivedUsersNames.indexOf(user.data.name), 1)
						sender.name.should.eql(chatuser1.name)
						_message.should.eql(message)
						done() if receivedMessages == 2
		false

	it "Should be able to send private messages to any user inside the room", (done) ->
		message = "Hello private world";

		setupUsers [chatuser1, chatuser2, chatuser3, chatuser4], {room: 'room1'}, ->
			users[0].emit("chat:message", message, {to: chatuser2.name})
			users.forEach (user) ->
				user.on "message", (_message, from) ->
					from.name.should.eql(chatuser1.name)
					user.data.name.should.eql(chatuser2.name)
					_message.should.eql(message)
					done()
		false

	it "Should be able for any user to switch the room", (done) ->
		changedRoomUsers = [chatuser2, chatuser3].map (u) ->
			u.name

		usersChangedRoomCount = 0

		setupUsers [chatuser1, chatuser2, chatuser3, chatuser4], {room: 'room1'}, ->
			users.forEach (user) ->
				user.on "chat:disconnected", (data) ->
					changedRoomUsers.should.include(data.name)

			users.slice(1,3).forEach (user) ->
				user.emit "chat:room", "room2"
				user.on "chat:connected", ->
					usersChangedRoomCount++
					changedRoomUsers.should.include(this.data.name)
					done() if usersChangedRoomCount is 2
		false

	false
