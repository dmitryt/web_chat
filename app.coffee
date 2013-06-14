
#
# Module dependencies.
#

express = require('express')
http = require('http')
path = require('path')

sockets = require('./sockets')
chat = require('./chat')

app = express()
server = http.createServer(app)

# all environments

app.configure ->
	app.set 'port', process.env.PORT || 8080
	app.set 'views', __dirname + '/views'
	app.set 'view engine', 'jade'
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use app.router
	app.use(express.static(path.join(__dirname, 'public')))

app.configure 'development', ->
	app.set 'address', 'localhost'
	app.use express.errorHandler
    	dumpExceptions: true,
    	showStack: true

app.use(express.logger('dev'))

# development only

app.use(express.errorHandler()) if 'development' == app.get('env')

# Routing
app.get '/', ->
	args = [].slice.call(arguments).concat([app])
	console.log('!!!!!!!!!!!!!!!', args)
	chat.login.apply(chat.login, [].slice.call(arguments).concat([app]))
app.post '/', chat.authorize

# Starting application
server.listen(app.get('port'))
sockets.init(server)