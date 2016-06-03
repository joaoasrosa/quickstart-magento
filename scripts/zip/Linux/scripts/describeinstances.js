var AWS = require('aws-sdk');
var myregion = process.env['AWS_DEFAULT_REGION'];
var myinstance = process.env['AWS_INSTANCEID'];
var mystack = process.env['PARENTSTACKNAME']
var cloudformation = new AWS.CloudFormation();

//AWS.config.update({region: region});
var ec2 = new AWS.EC2({region: region)});


function describe(func) {	
	if (myinstance) {
		var params = {
		};
		ec2.describeInstances(params, function(err, data) {
							 if (err) {
							 	func(null)
							 } else {
								console.log(JSON.stringify(data,null,4));      
							 	func(data);
							 }     
		});
	} else {
		func(null);
	}

}


describe(console.log);

