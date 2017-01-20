#!/bin/bash

# ------------------------------------------------------------------
#
#          Install prerequisites
#
# ------------------------------------------------------------------


usage() {
    cat <<EOF
    Usage: $0 [options]
        -h print usage
EOF
    exit 1
}

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then
    DIR="$PWD";
fi

LOG_FILE=/home/ec2-user/misc/log.txt

# ------------------------------------------------------------------
#          Output log
# ------------------------------------------------------------------

log() {
    echo $* 2>&1 | tee -a ${LOG_FILE}
}

while getopts ":h:b:" o; do
    case "${o}" in
        b) BUILDBUCKET=${OPTARG}
           BUILDBUCKET=$(echo ${BUILDBUCKET} | sed 's/"//g')
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))
[[ $# -gt 0 ]] && usage;

[ -e ${DIR}/config.sh ] && source ${DIR}/config.sh
[ -e ${DIR}/os.sh ] && source ${DIR}/os.sh

MAGENTO_TAR=$(basename ${MAGENTORELEASEMEDIA})
MAGENTO_EXTRACT_DIR=/var/www/html/magento

db_exist() {
	DBRESULT=$(mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME -e 'show databases;')
	if [[ $DBRESULT == *"magento"* ]];then
		echo "Database magento already exist!"
		return 0
	else
		echo "Database magento doesn't exist"
		return 1
	fi
}

create_db() {

    mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME << END
    DROP DATABASE if exists magento;
    create database magento;
    GRANT ALL ON magento.* TO 'magento'@'IP-NETMASK-REPLACEME' IDENTIFIED BY 'magento';
    GRANT ALL ON magento.* TO 'magento'@'IP-NETMASK-REPLACEME' IDENTIFIED BY 'magento';
END

}

am_i_oldest() {
	echo "Checking for the oldest instance"
	JQ_HOME="/home/ec2-user/misc/jq"
	EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
	EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
	GROUP=$(aws ec2 describe-tags --region=$EC2_REGION --filters "Name=resource-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" "Name=key,Values=aws:autoscaling:groupName" | $JQ_HOME .Tags[0].Value | sed 's/\"//g')
	IDS=$(aws autoscaling describe-auto-scaling-groups --region $EC2_REGION --auto-scaling-group-names $GROUP --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text | sed 's/\t/ /g')
	IPS=$(aws ec2 describe-instances --instance-ids $IDS --region $EC2_REGION --query Reservations[].Instances[].PrivateIpAddress --output text | sed 's/\t/,/g')
	LAUNCH_TIME=$(date -d $(aws ec2 describe-instances --region $EC2_REGION --instance-ids `curl -s http://169.254.169.254/latest/meta-data/instance-id` --query Reservations[].Instances[0].LaunchTime --output text))
	LAUNCH_TIMES=$(aws ec2 describe-instances --region $EC2_REGION --instance-ids $IDS --query Reservations[].Instances[].LaunchTime --output text)
	
	OLDEST=0
	for time in $LAUNCH_TIMES; do
	  if [[ `date -d $time` < $LAUNCH_TIME ]];
	  then
	    OLDEST=1
	    echo "I am not oldest"
	  fi
	done
	
	return $OLDEST
}

download_magento() {
	echo "Downloading Magento"
    mkdir -p ${MAGENTO_EXTRACT_DIR}
    cd ${MAGENTO_EXTRACT_DIR}
    /usr/local/bin/aws s3 cp ${MAGENTORELEASEMEDIA} .
    tar xvf ${MAGENTO_TAR}
    rm -f ${MAGENTO_TAR}
    echo "Downloading magento completed!"
}

setpermissions() {
    groupadd www
    usermod -a -G www ec2-user
    chmod 2775 /var/www

    echo "Setting permissions via setpermissions start"
    find /var/www/html/magento -type d | while read file; \
        do \
         chown apache $file;\
         chmod 2775 $file; \
    done

    find /var/www/html/magento -type f | while read file; \
        do \
         chown apache $file;\
         chmod 0664 $file; \
    done
	
	find /mnt -type d | while read file; \
        do \
         chown apache $file;\
         chmod 2775 $file; \
    done

    find /mnt -type f | while read file; \
        do \
         chown apache $file;\
         chmod 0664 $file; \
    done
    
    chown -R apache /var/www

    echo "Setting permissions via setpermissions end"
}

install_magento() {
	echo "Installing magento"
    cd ${MAGENTO_EXTRACT_DIR}/bin
    chmod +x magento
    /bin/sh /home/ec2-user/misc/scripts/cmdInstall.sh > /home/ec2-user/misc/magentoInstall.log 2>&1
    #/bin/sh /home/ec2-user/misc/scripts/cmdInstall.sh 2>&1 | tee /home/ec2-user/misc/magentoInstall.log
   	grep "Magento installation complete" /home/ec2-user/misc/magentoInstall.log
	RESULT=$?
	if [ $RESULT -eq 0 ];then
        echo "Installed Magento successfully!"
        adminURI=$(grep "Magento Admin URI" /home/ec2-user/misc/magentoInstall.log)
        echo $adminURI
    else
    	echo "Something went wrong with magento installation"
    fi
}

shared_media_exist() {
	if [[ -d /mnt/magento && `ls /mnt/magento | wc -l` > 0 ]];then
		echo "Shared media exist"
		return 0
	else
		echo "Shared media doesn't exist"
		return 1
	fi
}

move_media() {
	echo "Moving media to EFS"
	if ! shared_media_exist; then
		mkdir -p /mnt/magento
		service httpd stop
		cp -r /var/www/html/magento/pub/media /mnt/magento/
		rm -rf /var/www/html/magento/pub/media
		#mkdir -p /var/www/html/magento/pub/media
		ln -s /mnt/magento/media/ /var/www/html/magento/pub/
		service httpd start
		echo "Media moved to EFS"
	else
		echo "Media already in EFS"
		use_shared_media
	fi
}

use_shared_media() {
	echo "Preparing to use shared media"
	for (( c=0; c<=5; c++ ))
	do
		if shared_media_exist; then
			service httpd stop
			rm -rf /var/www/html/magento/pub/media
			#mkdir -p /var/www/html/magento/pub/media
			ln -s /mnt/magento/media/ /var/www/html/magento/pub/
			service httpd start
			echo "Using shared media now"
			return 0
		else
			echo "Waiting for shared media to be available..."
			/bin/sleep 60
		fi
	done
	echo "Unable to use shared media"
}

waitUntilDBisReady() {
	echo "Waiting until DB is ready and shared media available"
	MEDIANOTAVAILABLE=0
	while [ $MEDIANOTAVAILABLE -eq 0 ];do
		echo "Waiting for DB and shared media to be ready..."
		/bin/sleep 60
		if shared_media_exist; then
			MEDIANOTAVAILABLE=1
			echo "DB and shared media ready NOW!"
		fi
	done
}

writehomepage() {
    cp /home/ec2-user/misc/scripts/index.html /var/www/html/index.html
}

# just keep same copy.
[ -f /home/ec2-user/misc/config.sh ] && cp /home/ec2-user/misc/config.sh /home/ec2-user/misc/scripts

download_magento
setpermissions

IS_OLDEST=1
if am_i_oldest; then
	IS_OLDEST=0
	if ! db_exist;then
		create_db
	else
		echo "Some other instance is also oldest, and it beats me."
		echo "Hence, waiting for magento installation to complete by other instance and shared media available"
		waitUntilDBisReady
	fi
else
	echo "Wait until magento DB and shared media is available"
	waitUntilDBisReady
fi

/usr/bin/node /home/ec2-user/misc/scripts/cmdsetup.js

install_magento
setpermissions
writehomepage

if [[ $IS_OLDEST -eq 0 ]];then
	move_media
else
	echo "Pointing to shared media"
	use_shared_media
fi
setpermissions