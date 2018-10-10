#!/bin/sh

apt install zabbix-agent python sudo lm-sensors pwgen python-mysqldb
apt install --no-install-recommends smartmontools

mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf~

cat > /etc/zabbix/zabbix_agentd.conf <<__EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
DebugLevel=0
Timeout=30
Server=62.149.27.21
ListenPort=23450
ListenIP=0.0.0.0
ServerActive=62.149.27.21:10051
Hostname=`hostname`
Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf
Include=/etc/zabbix-agent.d/*.conf
__EOF



[ -d /var/run/zabbix ] || mkdir -p /var/run/zabbix && chown zabbix /var/run/zabbix
[ -d /var/log/zabbix ] || mkdir -p /var/log/zabbix && chown zabbix /var/run/zabbix

cd /opt

wget https://bitbucket.org/rvs/ztc/downloads/ztc-12.01.1.tar.gz
tar -zxf ztc-12.01.1.tar.gz
cd /opt/ztc-12.01.1

./setup.py install


cat >> /etc/zabbix/zabbix_agentd.conf.d/linux.conf <<__EOF

UserParameter=vfs.dev.discovery,echo -n '{"data":['; cat /proc/diskstats | awk '{print $3}' | while read drive ; do echo -n '{"{#DRIVE}":''"'$drive'"'}; done | sed 's/}{/},{/g' ; echo ']}'
__EOF

cat >> /etc/sudoers.d/zabbix <<__EOF

zabbix 127.0.0.1,localhost = NOPASSWD: /opt/ztc/bin/vfs_dev.py
__EOF

mv /etc/zabbix-agent.d/php.conf /etc/zabbix-agent.d/php.conf~

cat >> /etc/zabbix-agent.d/php.conf <<__EOFF
UserParameter=php.fpm.ping,/usr/bin/curl -w %{time_total} --no-keepalive -o /dev/null -sm15 http://127.0.0.1:8081/status
UserParameter=php.fpm.status[*],/usr/bin/curl --no-keepalive -sm3 http://127.0.0.1:8081/status | grep -e "^`echo $1 | tr _ \" \"`" | cut -d ':' -f 2 | tr -d ' '
__EOFF

cat >> /etc/nginx/sites-enabled/zabbix_mon.conf <<__EOFF
server {
        listen 127.0.0.1:8081;
        server_name _ ;
        location /server-status {
                stub_status on;
        }
        location /status {
            add_header FPM_Time $upstream_response_time;
            fastcgi_pass php;
            include /etc/nginx/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
        location /ping {
            fastcgi_pass php;
            include /etc/nginx/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        }

}
__EOFF

if [ -x /usr/bin/mysql ]
then
    p=`pwgen -ancs 20 1`
    mysql <<_EOFF
create database ztest;
grant all on ztest.* to ztest@'localhost' identified by '$p';
_EOFF
    cat > /etc/ztc/mysql.conf <<__EOFF
[main]
user=ztest
password=$p
database=ztest
host=localhost
__EOFF

fi


service zabbix-agent restart

