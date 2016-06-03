var AWS = require('aws-sdk');
var myregion = process.env['AWS_DEFAULT_REGION'];
var myec2 = process.env['AWS_INSTANCEID'];
var stack = require('./describestack.js');
var mystack = require('./describestack.js');
var __ = require('underscore');
var ec2 = new AWS.EC2({region: myregion});
var autoscaling = new AWS.AutoScaling({region: myregion});

var compareInstanceIds = function(a,b) {
	 var delta = parseInt(a.replace('i-',''), 16) - parseInt(b.replace('i-',''), 16);
	 return delta;
}

function getmyASindex(process) {
	var params = {};
	autoscaling.describeAutoScalingInstances(params, function(err, data) {
			if (err) {
			console.log(err, err.stack); // an error occurred
			process(err,null);
		}
		else {
			var as = data['AutoScalingInstances'];
			var i2as = [];
			var as2i = [];
			for (i in as) {
				var key = as[i];
				var instance = key['InstanceId'];
				var asGroup = key['AutoScalingGroupName'];
				i2as[instance] = asGroup;
				as2i[asGroup] =  as2i[asGroup] || [];
				as2i[asGroup].push(instance);
			}
			var myas = i2as[myec2];
			var myasInstances = as2i[myas];
			//myasInstances has all the instances in my AutoScaling group
			myasInstances = myasInstances.sort(compareInstanceIds);
			var myIndex = myasInstances.indexOf(myec2);
			process(null,myIndex);
		}     
	});
}



getmyASindex(function(err,myIndex) {
		if (err) {
			console.log(myIndex);
		} else {			
			console.log(myIndex);
		}

});

module.exports = getmyASindex;
