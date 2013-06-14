exports.login = (req, res, app) ->
	res.render app.get('views') + '/login.jade',
	    title: 'Login Page'
	false

exports.authorize = (req, res) ->
	false