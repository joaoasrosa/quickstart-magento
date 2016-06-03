var AWS = require('aws-sdk');
var myregion = process.env['AWS_DEFAULT_REGION'];
var stack = require('./describestack.js');
var mystack = require('./describestack.js');
var __ = require('underscore');
var ec2 = new AWS.EC2({region: myregion});

function print(json) {
	console.log(JSON.stringify(json,null,4));
}

function Subnets2CIDR(subnets) {
	//subnets are comma separated in template parameter
	var SubnetIds = subnets.split(',');
	console.log(SubnetIds);
	var params = {
		SubnetIds: SubnetIds
	};
	ec2.describeSubnets(params,function(err,data) {
		var cidr = __.pluck(data['Subnets'], 'CidrBlock');
		console.log(cidr);

	});	

}


function printmyCidrBlock(func) {
	stack.getmyParameter("WebServerSubnets",Subnets2CIDR);
}

//CidrBlock


var subnets = {
	"printmyCidrBlock": printmyCidrBlock
};

module.exports = subnets;
