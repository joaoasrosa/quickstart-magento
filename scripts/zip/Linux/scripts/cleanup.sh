#!/bin/bash

# ------------------------------------------------------------------
#
#          Cleanup!
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

#mv /home/ec2-user/misc /tmp

exit 0
