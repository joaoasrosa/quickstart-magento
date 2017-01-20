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

	wget https://s3.amazonaws.com/${BUILDBUCKET}/latest/scripts/zip/linux/scripts.zip --output-document=/home/ec2-user/misc/scripts.zip
	unzip scripts.zip -d /home/ec2-user/misc/scripts	
}

install_aws() {
    wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
    unzip awscli-bundle.zip
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws    
    export AWS=/usr/local/bin/aws
}

install_packages() {
	sudo yum install -y httpd24 php56 php56-opcache php56-mysqlnd mysql php56-gd php56-intl php56-mbstring php56-mcrypt php56-soap php56-xml
	echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
    sed -i '/<Directory "\/var\/www\/html/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
    sed -i "s/memory_limit.*/memory_limit = 512M/g" /etc/php.ini
    sed -i "s/;always_populate_raw_post_data.*/always_populate_raw_post_data = -1/g" /etc/php.ini
    sudo service httpd start
    # Configure the web server to start with each system boot
    sudo chkconfig httpd on
    yum --enablerepo=epel install -y php56* nodejs npm
    sudo service httpd restart                            
}

setMySQLcontext() {
    cd /home/ec2-user/misc/scripts
    sh /home/ec2-user/misc/scripts/setupMySQL.sh
}


cleanup() {
	mv /home/ec2-user/misc /tmp/
}

# ------------------------------------------------------------------
#          Install prereq software
# ------------------------------------------------------------------

download_scripts
install_aws
install_packages
setMySQLcontext

INSTALLOUTPUT=$(sh /home/ec2-user/misc/scripts/prereq.sh -b ${BUILDBUCKET} > /home/ec2-user/misc/install.log 2>&1)

#   restart apache
sudo service httpd restart 

cleanup
