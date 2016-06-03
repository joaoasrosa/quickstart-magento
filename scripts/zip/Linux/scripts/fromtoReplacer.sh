#!/bin/bash 

# ------------------------------------------------------------------
# Import variables from CloudFormation template into download.sh
# ------------------------------------------------------------------

export PATH=${PATH}:/sbin:/usr/sbin:/usr/local/sbin:/root/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/X11R6/bin:/usr/games:/usr/lib/AmazonEC2/ec2-api-tools/bin:/usr/lib/AmazonEC2/ec2-ami-tools/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin

usage() { 
    cat <<EOF
    Usage: $0 [from=to] file
EOF
    exit 0
}


# ------------------------------------------------------------------
#          Read all inputs
# ------------------------------------------------------------------


[[ $# -ne 2 ]] && usage;
fromto=$1
file=$2

[ ! -e $file ] && usage;
from=$(echo $fromto | awk -F'=' '{print $1}')
to=$(echo $fromto | awk -F'=' '{print $2}')


to=$(echo ${to} | sed -e 's/[\/&]/\\&/g')


echo "$from: $to in $file"
sed -i  "s/${from}/${to}/g" $file
