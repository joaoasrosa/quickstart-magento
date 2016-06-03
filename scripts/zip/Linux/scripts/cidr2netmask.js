var Netmask = require('netmask').Netmask;
var stack = require('./describestack.js');
var subnets = require('./describesubnets.js');

function print(json) {
	for (i in json) {
		var v = json[i];
		var block = new Netmask(v);
		block['CidrBlock'] = v;
		console.log(JSON.stringify(block,null,4));
	}
}


stack.getmyCIDR(print);
