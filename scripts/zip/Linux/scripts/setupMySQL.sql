mysql -u RDSUSER-REPLACE-ME --password=PASSWORD-REPLACE-ME -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME 

create database magento;
GRANT ALL ON magento.* TO 'magento'@'IP-NETMASK-REPLACEME' IDENTIFIED BY 'magento';
GRANT ALL ON magento.* TO 'magento'@'IP-NETMASK-REPLACEME' IDENTIFIED BY 'magento';

#mysql -u magento -h RDS-HOST-REPLACEME  -P RDS-PORT-REPLACEME --password=magento -p magento < /home/ec2-user/misc/magento-sample-data-1.9.0.0/magento_sample_data_for_1.9.0.0.sql

#mysql -u magento -h RDS-HOST-REPLACEME -P RDS-PORT-REPLACEME --password=magento 