#!/bin/bash

# ------------------------------------------------------------------
#    Get input parameter from parent stack
# ------------------------------------------------------------------

usage() {
    cat <<EOF
    Usage: $0 [options]
        -h print usage
        -k Stack Parameter Key value
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



while getopts ":h:k:" o; do
    case "${o}" in
        k) KEY=${OPTARG}
		   KEY=$(echo ${KEY} | sed 's/"//g')
			;;
        *)
            usage
            ;;

    esac
done

shift $((OPTIND-1))
[[ $# -gt 0 ]] && usage;

[ -e ${DIR}/config.sh ] && source ${DIR}/config.sh > /dev/null 2>&1
[ -e ${DIR}/os.sh ] && source ${DIR}/os.sh  > /dev/null 2>&1

INPUT=$(aws cloudformation describe-stacks --stack-name ${PARENTSTACKNAME} \
   | ${JQ_COMMAND} -c --arg key "$KEY" '.Stacks[].Parameters | .[] |  select(.ParameterKey | contains($key)) | .ParameterValue')

echo ${INPUT}

##export PARENTSTACKNAME=mag1-WebServer-XFDIS0AMJ5CB