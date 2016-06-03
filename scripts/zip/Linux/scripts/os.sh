# ------------------------------------------------------------------
#          RHEL or SUSE or Amazon Linux or Generic
# ------------------------------------------------------------------

isRHEL() {
    if [ "$MyOS" == "RHEL" ]; then
        echo 1
    else
      echo 0
    fi
}
isSUSE() {
    if [ "$MyOS" == "SUSE" ]; then
      echo 1
    else
      echo 0
    fi
}

isAmazonLinux() {
	[ ! -f /etc/os-release ] && echo 0 && return;
	id=$(cat /etc/os-release | grep "ID=" | grep -v VERSION | sed 's/ID=//g' | sed 's/"//g')
    if [ "$id" == "amzn" ]; then
      echo 1
    else
      echo 0
    fi
}


