module.exports = (app) ->
	# Routing
	app.get '/', (req, res) -> 
		res.render app.get('views') + '/login',
		    title: 'Login Page'
		false

	app.post '/', (req, res, app) ->
		false