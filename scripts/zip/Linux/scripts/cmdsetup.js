var Netmask = require('netmask').Netmask;
var stack = require('./describestack.js');
var subnets = require('./describesubnets.js');
var fs = require('fs');
var AWS = require('aws-sdk');
var myregion = process.env['AWS_DEFAULT_REGION'];
var myinstance = process.env['AWS_INSTANCEID'];
var mystack = process.env['PARENTSTACKNAME'];
var rdsstack = process.env['RDSMySQLStack'];
var cloudformation = new AWS.CloudFormation({region: myregion});
var ec2 = new AWS.EC2({region: myregion});
var __ = require('underscore');


//AWS.config.update({region: region});
var ec2 = new AWS.EC2({region: myregion});


function setELBUNUSED() {
	var base = __dirname + '/' + 'cmdInstall.sh';
	var contents = fs.readFileSync(base).toString();
	var params = {
		StackName: mystack
	};
	cloudformation.describeStacks(params,function(err,data) {
						var json = data;
						if (!err) {
							var outputs = data['Stacks'][0]['Outputs'];
							var val = __.find(outputs,function(item) {
								return item.OutputKey === 'URL';
							});
							var URL = val['OutputValue'];

							contents = contents.replace(/ELB-URL-REPLACE-ME/g,URL);

							console.log(contents);

							fs.writeFileSync(base, contents);


						} else {
							console.log(err);
						}
		});

}

function setRDS() {
	var base = __dirname + '/' + 'cmdInstall.sh';
	var contents = fs.readFileSync(base).toString();
	var rdsPassword = process.env['DBMasterUserPassword'];
	var rdsUsername= process.env['DBMasterUsername'];
	var params = {
		StackName: rdsstack
	};
		
	cloudformation.describeStacks(params,function(err,data) {
						var json = data;
						if (!err) {
							var outputs = data['Stacks'][0]['Outputs'];
							var val = __.find(outputs,function(item) {
								return item.OutputKey === 'MySQLEndPointAddress';
							});
							var endpoint = val['OutputValue'];
							var val = __.find(outputs,function(item) {
								return item.OutputKey === 'MySQLEndPointPort';
							});
							var port = val['OutputValue'];

							contents = contents.replace(/RDS-HOST-REPLACEME/g,endpoint);
							contents = contents.replace(/RDS-PORT-REPLACEME/g,port);
							contents = contents.replace(/RDS-HOST-REPLACEME/g,endpoint);
							contents = contents.replace(/RDS-PORT-REPLACEME/g,port);
							contents = contents.replace(/PASSWORD-REPLACE-ME/g,rdsPassword);
							contents = contents.replace(/RDSUSER-REPLACE-ME/g,rdsUsername);

							console.log(contents);

							fs.writeFileSync(base, contents);

						} else {
							console.log(err);
						}
		});

}

//setELB();

setRDS();
