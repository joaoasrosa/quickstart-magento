#!/bin/bash

# ------------------------------------------------------------------
#    set baseline config info (such as AWS_DEFAULT_ZONE)
# ------------------------------------------------------------------


export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export PATH=${PATH}:/sbin:/usr/sbin:/usr/local/sbin:/root/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/X11R6/bin:/usr/games:/usr/lib/AmazonEC2/ec2-api-tools/bin:/usr/lib/AmazonEC2/ec2-ami-tools/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin

mkdir -p /home/ec2-user/misc
[ -z ${JQ_COMMAND} ] && export JQ_COMMAND=/home/ec2-user/misc/jq

if [ -f ${JQ_COMMAND} ]; then
	echo "JQ Already exists!"
else
	wget https://s3.amazonaws.com/quickstart-reference/magento/latest/media/jq --output-document ${JQ_COMMAND}
fi
chmod  755 ${JQ_COMMAND}

if [ -z ${AWS_DEFAULT_REGION} ]; then
	 export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document \
					| ${JQ_COMMAND} '.region'  \
					| sed 's/^"\(.*\)"$/\1/' )
fi
if [ -z ${AWS_DEFAULT_AVAILABILITY_ZONE} ]; then
	 export AWS_DEFAULT_AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document \
						| ${JQ_COMMAND} '.availabilityZone' \
						| sed 's/^"\(.*\)"$/\1/' )
fi

if [ -z ${AWS_INSTANCEID} ]; then
	 export AWS_INSTANCEID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document \
						| ${JQ_COMMAND} '.instanceId' \
						| sed 's/^"\(.*\)"$/\1/' )
fi


# ------------------------------------------------------------------
#          remove double quotes, if any. cli doesn't like it!
# ------------------------------------------------------------------

export AWS_DEFAULT_REGION=$(echo ${AWS_DEFAULT_REGION} | sed 's/^"\(.*\)"$/\1/' )
export AWS_DEFAULT_AVAILABILITY_ZONE=$(echo ${AWS_DEFAULT_AVAILABILITY_ZONE} | sed 's/^"\(.*\)"$/\1/' )
export AWS_INSTANCEID=$(echo ${AWS_INSTANCEID} | sed 's/^"\(.*\)"$/\1/' )




