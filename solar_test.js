    var fs = require('fs');
var settings = {
  encoding: "utf8"
  };
var page = require('webpage').create();
page.open('1.html',settings, function (status) {
    if (status !== 'success') {
        console.log('Unable to load the address!');
        phantom.exit();
    } else {
        window.setTimeout(function () {
            page.render('test.png');
    fs.write('2.html', page.content, 'b');
            phantom.exit();
        }, 5000); // Change timeout as required to allow sufficient time 
    }
});

//   var page = new WebPage()
//    var fs = require('fs');
//
//    page.onLoadFinished = function() {
//      console.log("page load finished");
//      page.render('export.png');
//      fs.write('1.html', page.content, 'w');
//      phantom.exit();
//    };
//
//    page.open('http://localhost/solar_data/solar_output.html', function() {
//      page.evaluate(function() {
//      });
//    });

//    page.onLoadFinished = function() {
//        console.log("page load finished");
//        page.render('export.png');
//        fs.write('1.html', page.content, 'w');
//        phantom.exit();
//    };
