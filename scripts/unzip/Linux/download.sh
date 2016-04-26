#!/bin/bash

usage() {
	cat <<EOF
		Usage: $0 [options]
			-h print usage
			-b S3 BuildBucket that contains misc/scripts/download.zip
EOF
		exit 1
}

# ------------------------------------------------------------------
#          Read all inputs
# ------------------------------------------------------------------


while getopts ":h:b:" o; do
	case "${o}" in
		h) usage && exit 0
			;;
		b) BUILDBUCKET=${OPTARG}
		   BUILDBUCKET=$(echo ${BUILDBUCKET} | sed 's/"//g')
			;;
		*)
			usage
			;;
		esac
done

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then 
	DIR="$PWD"; 
fi

source ${DIR}/config.sh

download_scripts() {
	chown -R ec2-user:ec2-user /home/ec2-user/
	mkdir -p /home/ec2-user/misc/scripts
	cd /home/ec2-user/misc

	wget https://s3.amazonaws.com/${BUILDBUCKET}/magento/latest/scripts/zip/Linux/scripts.zip --output-document=/home/ec2-user/misc/scripts.zip
	unzip scripts.zip  -d /home/ec2-user/misc/scripts	
}

setMySQLcontext() {
    cd /home/ec2-user/misc/scripts
    sh /home/ec2-user/misc/scripts/setupMySQL.sh
    #source /home/ec2-user/misc/config.sh  && /usr/bin/node mysqlsetup.js
}

install_aws() {
    wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
    unzip awscli-bundle.zip
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws    
    export AWS=/usr/local/bin/aws
}

install_node() {
    yum --enablerepo=epel install node npm -y

}

cleanup() {
	CLEAN=/home/ec2-user/misc/scripts/cleanup.sh
	[ -f ${CLEAN} ] && sh ${CLEAN}
}

# ------------------------------------------------------------------
#          Install prereq software
# ------------------------------------------------------------------

download_scripts
install_aws
install_node
setMySQLcontext

INSTALLOUTPUT=$(sh /home/ec2-user/misc/scripts/prereq.sh -b ${BUILDBUCKET} > /home/ec2-user/misc/install.log 2>&1)
echo ${INSTALLOUTPUT}

#   restart apache
apachectl -k restart

# cleanup
cleanup

