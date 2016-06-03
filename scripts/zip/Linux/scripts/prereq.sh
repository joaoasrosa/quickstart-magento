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

CACHEDIR=/s3fscache
LOG_FILE=/home/ec2-user/misc/log.txt
#MAGENTO_TAR=magento-1.9.2.0.tar-2015-07-08-02-50-14.gz
#MAGENTO_SAMPLE=magento-sample-data-1.9.0.0.tar.gz
FILEREPLACER=/home/ec2-user/misc/scripts/fromtoReplacer.sh
PHPCONF=/etc/httpd/conf.d/phpMyAdmin.conf
PHPREMOTECONFIG=/home/ec2-user/misc/scripts/phpAccess.txt
FUSE_TAR=fuse-2.9.4.tar.gz

mkdir -p ${CACHEDIR}
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

if [ -z ${MAGENTOSAMPLEDATA} ]; then
	INSTALLMAGENTOSAMPLE=0
else
	INSTALLMAGENTOSAMPLE=1
fi
MAGENTO_TAR=$(basename ${MAGENTORELEASEMEDIA})
MAGENTO_SAMPLE=$(basename ${MAGENTOSAMPLEDATA})
MAGENTO_SAMPLE_VERSION=$(echo ${MAGENTO_SAMPLE} | awk -F'.tar' '{print $1}' | sed 's/magento-sample-data-//g')
##MAGENTO_TAR_VERSION=$(echo ${MAGENTO_TAR} | awk -F'.tar' '{print $1}' | sed 's/magento-//g')
MAGENTO_EXTRACT_DIR=/home/ec2-user/misc/magento/install
MAGENTO_SAMPLEEXTRACT_DIR=/home/ec2-user/misc/magento/sample

install_mysql56() {
    yum localinstall http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm -y
    yum install mysql-community-server -y
}

install_php55() {
     yum install php55 -y
}

install_phpmyadmin() {
	cd /home/ec2-user/misc
	#wget https://files.phpmyadmin.net/phpMyAdmin/4.4.11/phpMyAdmin-4.4.11-all-languages.zip
	#unzip  phpMyAdmin-4.4.11-all-languages.zip -d /var/www/html
	#PHPDIR=$(find . -name "phpMyAd*" -type d)

	yum --enablerepo=epel install phpmyadmin -y
	ln -s  /usr/share/phpMyAdmin/ /var/www/html/
}


install_misc() {
    cd /home/ec2-user/misc
    mkdir -p /var/www/html/validate
    echo '<?php phpinfo(); ?>' > /var/www/html/validate/phpinfo.php
}



download_magento() {
    mkdir -p ${MAGENTO_EXTRACT_DIR}
    cd ${MAGENTO_EXTRACT_DIR}
    wget https://s3.amazonaws.com/${BUILDBUCKET}/magento/latest/media/magento-check.zip
    /usr/local/bin/aws s3 cp ${MAGENTORELEASEMEDIA} .
    tar xvf ${MAGENTO_TAR}

    if (( ${INSTALLMAGENTOSAMPLE} == 1 )); then
        mkdir -p ${MAGENTO_SAMPLEEXTRACT_DIR}
        cd ${MAGENTO_SAMPLEEXTRACT_DIR}
        /usr/local/bin/aws s3 cp ${MAGENTOSAMPLEDATA} .
        tar xvf ${MAGENTO_SAMPLE}
    fi
}

install_packages() {
    cd /home/ec2-user/misc/scripts
    npm install
    npm install netmask
    npm install minimist
    npm install aws-sdk
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

    find ${CACHEDIR} -type d | while read file; \
        do \
         chown apache $file;\
         chmod 2775 $file; \
    done

    find ${CACHEDIR} -type f | while read file; \
        do \
         chown apache $file;\
         chmod 0664 $file; \
    done



#    [ -d /var/www/html/magento/ ] && chmod -R a+w /var/www/html/magento/
    chown -R apache /var/www

    echo "Setting permissions via setpermissions end"


}

install_magento() {
    service httpd stop
    cd /home/ec2-user/misc/scripts
    cat httpd.conf >> /etc/httpd/conf/httpd.conf

    MAGENTO_INSTALL_PHP=$(find ${MAGENTO_EXTRACT_DIR} -name install.php)
    MAGENTO_ROOT=$(dirname ${MAGENTO_INSTALL_PHP})
    mkdir -p /var/www/html
    echo "cp -r ${MAGENTO_ROOT} /var/www/html/magento"
    cp -r ${MAGENTO_ROOT} /var/www/html/magento
    #cp -r /home/ec2-user/misc/magento /var/www/html/magento

    wget https://s3.amazonaws.com/${BUILDBUCKET}/magento/latest/media/magento-check.zip
    unzip magento-check.zip -d /var/www/html/validate/

}

create_db() {

    mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME << END
    DROP DATABASE if exists magento;
    create database magento;
    GRANT ALL ON magento.* TO 'magento'@'IP-NETMASK-REPLACEME' IDENTIFIED BY 'magento';
    GRANT ALL ON magento.* TO 'magento'@'IP-NETMASK-REPLACEME' IDENTIFIED BY 'magento';
END

}

install_magento_sample() {

    MAGENTO_INSTALL_SKIN=$(find ${MAGENTO_SAMPLEEXTRACT_DIR} -name skin -type d)
    MAGENTO_SAMPLE_ROOT=$(dirname ${MAGENTO_INSTALL_SKIN})
    MAGENTO_SQL_FILE=$(find $MAGENTO_SAMPLE_ROOT -maxdepth 1 -name "*.sql")
    #cp -r /home/ec2-user/misc/magento-sample-data-${MAGENTO_SAMPLE_VERSION}/media/* /var/www/html/magento/media/
    #cp -r /home/ec2-user/misc/magento-sample-data-${MAGENTO_SAMPLE_VERSION}/skin/* /var/www/html/magento/skin/
    #cp /home/ec2-user/misc/magento-sample-data-${MAGENTO_SAMPLE_VERSION}/magento_sample_data_for_${MAGENTO_SAMPLE_VERSION}.sql /home/ec2-user/misc/scripts

    cp -r ${MAGENTO_SAMPLE_ROOT}/media/* /var/www/html/magento/media/
    cp -r ${MAGENTO_SAMPLE_ROOT}/skin/* /var/www/html/magento/skin/
    cp ${MAGENTO_SQL_FILE} /home/ec2-user/misc/scripts

    #mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME magento < /home/ec2-user/misc/magento-sample-data-${MAGENTO_SAMPLE_VERSION}/magento_sample_data_for_${MAGENTO_SAMPLE_VERSION}.sql
    echo "mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME magento < ${MAGENTO_SQL_FILE}"
    mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME magento < ${MAGENTO_SQL_FILE}

}

install_s3fuse() {
    cd /home/ec2-user/misc
    yum install git -y
    yum install libcurl* -y

    #wget https://s3.amazonaws.com/${BUILDBUCKET}/magento/latest/media/${FUSE_TAR} --output-document=/home/ec2-user/misc/${FUSE_TAR}
	#wget http://skylineservers.dl.sourceforge.net/project/fuse/fuse-2.X/2.9.4/fuse-2.9.4.tar.gz --output-document=/home/ec2-user/misc/${FUSE_TAR}
    wget https://s3.amazonaws.com/quickstart-reference/magento/latest/media/fuse-2.9.4.tar.gz --output-document=/home/ec2-user/misc/${FUSE_TAR}

    #wget https://s3.amazonaws.com/${BUILDBUCKET}/magento/latest/media/v1.79.zip
	#wget https://github.com/s3fs-fuse/s3fs-fuse/archive/v1.79.zip
    wget https://s3.amazonaws.com/quickstart-reference/magento/latest/media/v1.79.zip

    cd /home/ec2-user/misc
    tar xvf fuse-2.9.4.tar.gz
    cd fuse-2.9.4
    sh ./configure --prefix=/usr
    make
    make install
    ldconfig
    export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig/:/home/ec2-user/misc/fuse-2.9.4


    cd /home/ec2-user/misc
    unzip v1.79.zip
    cd s3fs-fuse-1.79
    yum install fuse libcurl libxml* -y
    yum install gcc libstdc++-devel gcc-c++ curl-devel libxml2-devel openssl-devel mailcap
    sh ./autogen.sh
    sh ./configure --prefix=/usr
    make
    make install
    ldconfig

}

waituntilS3store() {
    MARKCOMPLETE=$(/usr/local/bin/aws s3 ls --recursive s3://${MAGENTOMEDIAS3}/magento/media/markcomplete.txt | wc -l)
    MEDIAMAXCOUNT=1
    while [ $MARKCOMPLETE -lt $MEDIAMAXCOUNT ];do
        MARKCOMPLETE=$(/usr/local/bin/aws s3 ls --recursive s3://${MAGENTOMEDIAS3}/magento/media/markcomplete.txt | wc -l)
        MEDIACOUNT=$(/usr/local/bin/aws s3 ls --recursive s3://${MAGENTOMEDIAS3}/magento/media/ | wc -l)
        echo "Current S3 stored $MEDIACOUNT (MARKCOMPLETE=${MARKCOMPLETE})"
        sleep 60
    done
    echo "All done! Current S3 stored $MEDIACOUNT (MARKCOMPLETE=${MARKCOMPLETE})"
}



initS3magento() {
    MEDIAFC=$(/usr/local/bin/aws s3 ls s3://${MAGENTOMEDIAS3}/magento/media/ | wc -l)
    if (( ${MEDIAFC} < 2 ));then
        echo "Nothing in shared S3 media. Will move local files firsttime".
        #cp -r /var/www/html/magento/media/ /mnt/magento/
        /usr/local/bin/aws s3 cp --recursive /var/www/html/magento/media/ s3://${MAGENTOMEDIAS3}/magento/media
        /usr/local/bin/aws s3 cp /home/ec2-user/misc/scripts/markcomplete.txt s3://${MAGENTOMEDIAS3}/magento/media/
        rm -rf /var/www/html/magento/media/
        ln -s /mnt/magento/media/ /var/www/html/magento/
        chown -R apache /var/www
        chown -R apache /var/www
    else
        echo "Shared S3 media exists! Will link to it locally".
        rm -rf /var/www/html/magento/media/
        mkdir -p /var/www/html/magento/
        ln -s /mnt/magento/media/ /var/www/html/magento/
        chown -R apache /var/www
        chown -R apache /mnt/magento/
    fi
}

lnS3magento() {
    echo "Shared S3 media exists! Looks like other node beat me to it!".
    echo "Will just link to the S3 bucket"
    rm -rf /var/www/html/magento/media/
    mkdir -p /var/www/html/magento/
    ln -s /mnt/magento/media/ /var/www/html/magento/
    chown -R apache /var/www
    chown -R apache /mnt/magento/
}


# ------------------------------------------------------------------
#          Check if S3 shared media is empty or not
#          Even if other node is adding at that time, don't overwrite
# ------------------------------------------------------------------


ifFirstnode() {
    MYINDEX=$(/usr/bin/node /home/ec2-user/misc/scripts/myASindex.js)
    if (( $MYINDEX == 0 )); then
        echo 1
    else
        echo 0
    fi
}

ifmediaempty() {
    MEDIAFC=$(/usr/local/bin/aws s3 ls --recursive s3://${MAGENTOMEDIAS3}/magento/media/ | wc -l)
    if (( ${MEDIAFC} > 2 ));then
        echo 0
    else
        echo 1
    fi
}

mountS3magento() {
    /bin/chown ec2-user:ec2-user /home/ec2-user/.passwd-s3fs
    /bin/chmod 600 /home/ec2-user/.passwd-s3fs
    mkdir -p /mnt
    # debug options for s3fs -d -d -f -o f2 -o curldbg
    echo "/usr/bin/s3fs -o default_acl=public-read -o use_cache=${CACHEDIR},allow_other,user=apache -o passwd_file=/home/ec2-user/.passwd-s3fs ${MAGENTOMEDIAS3} /mnt"
    OUT=$(/usr/bin/s3fs -o default_acl=public-read -o use_cache=${CACHEDIR},allow_other,user=apache -o passwd_file=/home/ec2-user/.passwd-s3fs ${MAGENTOMEDIAS3} /mnt 2>&1)
    echo ${OUT}

    echo "s3fs#${MAGENTOMEDIAS3} /mnt fuse use_cache=${CACHEDIR},allow_other,user=apache,passwd_file=/home/ec2-user/.passwd-s3fs 0 0" >> /etc/fstab

    # Not sure if this is needed.
    mkdir -p /mnt/magento/media

}

warmcache() {
    /usr/local/bin/aws s3 cp --recursive  s3://${MAGENTOMEDIAS3}/magento/media/ ${CACHEDIR}/${MAGENTOMEDIAS3}/magento/media/
}

setphpMyAdminAccess() {
    REMOTEACCESSCIDR=$(sh /home/ec2-user/misc/scripts/getStackInput.sh -k RemoteAccessCIDR)
    REMOTEACCESSCIDR=$(echo $REMOTEACCESSCIDR | sed 's/^"\(.*\)"$/\1/')

    sh ${FILEREPLACER} REMOTEACCESSCIDR-REPLACE-ME=${REMOTEACCESSCIDR} ${PHPREMOTECONFIG}

    LEADTAG=$(echo "<Directory /usr/share/phpMyAdmin/>")
    TAILTAG=$(echo "</Directory>")
    NEWPHPCONF=/tmp/phpMyAdmin.conf

    cp ${PHPCONF} ${PHPCONF}.backup

    echo -n "" >  ${NEWPHPCONF}

    FOUND=0
    while IFS= read line
    do
        if [[ $line == "$LEADTAG"* ]]; then
            cat ${PHPREMOTECONFIG} >> ${NEWPHPCONF}
            FOUND=1
        fi
        if (( $FOUND == 0 )); then
            echo "$line" >> ${NEWPHPCONF}
        fi
        if [[ $line == *"$TAILTAG"* ]]; then
            FOUND=0
        fi
    done < ${PHPCONF}

    cp ${NEWPHPCONF} ${PHPCONF}

}

writehomepage() {
    cd /home/ec2-user/misc/scripts
    if (( ${INSTALLMAGENTOSAMPLE} == 1 )); then
        cp index_withsample.html /var/www/html/index.html
    else
        cp index_default.html /var/www/html/index.html
    fi

}

if (( $(isRHEL) == 1 )); then
    echo "RHEL"
elif (( $(isSUSE) == 1 ));then
    echo "SuSE"
elif (( $(isAmazonLinux) == 1 )); then
    yum install update -y
    #install_aws
    install_mysql56
    install_php55
    #setpermissions
    install_misc
    install_phpmyadmin
    #install_node

#   apache rewrite
    sed -i '/<Directory "\/var/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf

#   php extentions
    yum install -y php55-devel php55-mhash php55-mcrypt php55-mcurl php55-cli php55-mysql php55-gd libapache2-mod-php5 libapache2-mod-php55
#   pick the missing ones from epel
    yum --enablerepo=epel install -y php55*


#   php memory
    sed -i "s/memory_limit.*/memory_limit = 512M/g" /etc/php.ini
    sed -i "s/short_open_tag.*=.*/short_open_tag = On /g" /etc/php.ini


    chown -R ec2-user:ec2-user /home
    # just keep same copy.
    [ -f /home/ec2-user/misc/config.sh ] && cp /home/ec2-user/misc/config.sh /home/ec2-user/misc/scripts




    download_magento
    install_magento
    setpermissions
    setphpMyAdminAccess
    writehomepage

    install_s3fuse
    /usr/bin/node /home/ec2-user/misc/scripts/cmdsetup.js

    if (( ${INSTALLMAGENTOSAMPLE} == 1 )); then
        if (( $(ifmediaempty) == 1  && $(ifFirstnode) == 1 )); then
            create_db
            install_magento_sample
            mountS3magento
            initS3magento
            warmcache
            setpermissions
            apachectl -k restart
            echo "Install magento via command line (main node that created s3 media)"
            echo "Install magento via command line (no sample data)"
            for (( try=0; try<8; ++try ));
            do
                RESULT=$(/bin/sh /home/ec2-user/misc/scripts/cmdInstall.sh | grep "already installed" | wc -l)
                if (( $RESULT == 1 ));then
                    echo "Installed Magento. Exiting"
                    break
                else
                    /bin/sleep 60
                fi
            done
            setpermissions
            apachectl -k restart
        else
            echo "Will wait for other node to complete!"
            waituntilS3store
            mountS3magento
            lnS3magento
            warmcache
            setpermissions
            apachectl -k restart
            echo "Install magento via command line (secondary feeder nodes)"
            echo "Install magento via command line (no sample data)"
            for (( try=0; try<8; ++try ));
            do
                RESULT=$(/bin/sh /home/ec2-user/misc/scripts/cmdInstall.sh | grep "already installed" | wc -l)
                if (( $RESULT == 1 ));then
                    echo "Installed Magento. Exiting"
                    break
                else
                    /bin/sleep 60
                fi
            done

            setpermissions
            apachectl -k restart
        fi
    else
        if (( $(ifFirstnode) == 1 )); then
            create_db
        fi
        echo "Install magento via command line (no sample data)"
        for (( try=0; try<8; ++try ));
        do
            RESULT=$(/bin/sh /home/ec2-user/misc/scripts/cmdInstall.sh | grep "already installed" | wc -l)
            if (( $RESULT == 1 ));then
                echo "Installed Magento. Exiting"
                break
            else
                /bin/sleep 60
            fi
        done
        apachectl -k restart
    fi

fi

exit 0
