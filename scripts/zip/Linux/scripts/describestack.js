var AWS = require('aws-sdk');
var myregion = process.env['AWS_DEFAULT_REGION'];
var myinstance = process.env['AWS_INSTANCEID'];
var mystack = process.env['PARENTSTACKNAME']
var cloudformation = new AWS.CloudFormation({region: myregion});
var ec2 = new AWS.EC2({region: myregion});
var __ = require('underscore');


//AWS.config.update({region: region});
var ec2 = new AWS.EC2({region: myregion});

function print(json) {
	console.log(JSON.stringify(json,null,4));
}

function getStackparameter(key,json,stackindex) {
	var params = json['Stacks'][stackindex]['Parameters'];
	var val = __.find(params,function(item) {
			return item.ParameterKey === key;
		});
	return val.ParameterValue;
}


function Subnets2CIDR(subnets,func) {
	//subnets are comma separated in template parameter
	var SubnetIds = subnets.split(',');
	var params = {
		SubnetIds: SubnetIds
	};
	ec2.describeSubnets(params,function(err,data) {
		if (!err) {
			var cidr = __.pluck(data['Subnets'], 'CidrBlock');
			func(cidr);			
		} else {
			console.log(err);
		}
	});	

}


function getmyParameter(key,func) {	
	if (mystack) {
		var params = {
			StackName: mystack
		};
		cloudformation.describeStacks(params,function(err,data) {
						var json = data;
						if (!err) {
							var vals = getStackparameter(key,data,0);
							func(vals);
						} else {
							console.log(err);
							func(null);
						}
		});


	} else {
		func(null);
	}
}

function getmyCIDR(func) {
	if (mystack) {
		var params = {
			StackName: mystack
		};
		var key = "WebServerSubnets";
		cloudformation.describeStacks(params,function(err,data) {
						var json = data;
						if (!err) {
							var vals = getStackparameter(key,data,0);
							Subnets2CIDR(vals,func);
						} else {
							console.log(err);
							func(null);
						}
		});


	} else {
		func(null);
	}
}




var stack = {
	"print": print,
	"getmyParameter": getmyParameter,
	"getmyCIDR": getmyCIDR
};

module.exports = stack;
