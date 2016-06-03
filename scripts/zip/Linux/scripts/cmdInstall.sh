source /home/ec2-user/misc/config.sh

ELBSMALLURL=$(echo ${ELBURL} | awk '{print tolower($0)}')


php -f /var/www/html/magento/install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "RDS-HOST-REPLACEME:RDS-PORT-REPLACEME" \
--db_name "magento" \
--db_user "RDSUSER-REPLACE-ME" \
--db_pass "PASSWORD-REPLACE-ME" \
--url "${ELBSMALLURL}/magento/" \
 --secure_base_url "${ELBSMALLURL}/magento/" \
--use_rewrites "yes" \
--use_secure "no" \
--use_secure_admin "no" \
--admin_firstname "magento" \
--admin_lastname "quickstart" \
--admin_email "foo@bar.com" \
--admin_username "RDSUSER-REPLACE-ME" \
--admin_password "PASSWORD-REPLACE-ME"  \
--skip_url_validation       
