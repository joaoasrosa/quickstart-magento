source /home/ec2-user/misc/config.sh

ELBSMALLURL=$(echo ${ELBURL} | awk '{print tolower($0)}')


./magento setup:install \
--language=en_US \
--timezone="America/Los_Angeles" \
--currency="USD" \
--db-host="RDS-HOST-REPLACEME:RDS-PORT-REPLACEME" \
--db-name="magento" \
--db-user="RDSUSER-REPLACE-ME" \
--db-password="PASSWORD-REPLACE-ME" \
--base-url="${ELBSMALLURL}/magento/" \
--use-rewrites=1 \
--admin-firstname="magento" \
--admin-lastname="quickstart" \
--admin-email="foo@bar.com" \
--admin-user="RDSUSER-REPLACE-ME" \
--admin-password="PASSWORD-REPLACE-ME" \
--backend-frontname="admin_m0h07"