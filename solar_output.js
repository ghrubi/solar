#!/usr/bin/phantomjs

var url = 'http://cms.asskick.com/solar_data/1.html';

var page = require('webpage').create();
page.open(url, function(status) {
	console.log("Status: " + status);
	if (status === "success") {
		page.render('test.png');
	}
	phantom.exit();
});

