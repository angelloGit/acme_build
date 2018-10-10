# acme_build
# zabbix_agent + ztc

acme  собирает из исходников acme-client 
добавляет в системе каталоги поумолчанию для программы
добавляет в nginx настройка для челенжа с letscrypt . 
в любом случае нужно руками добавить 'include /etc/nginx/conf/acme;'  в нужній server{...} nginx-а
и вручную запуск 
	/usr/local/bin/acme-client -vvvmnN <some domain>
если все удачно, сертификат в 
	/etc/ssl/acme/<some domain>/fullchain.pem
ключ 
	/etc/ssl/acme/private/<some domain>/privkey.pem
соответственно добавить в конфиг nginx-a
    ssl_certificate                /etc/ssl/acme/<some domain>/fullchain.pem;
    ssl_certificate_key            /etc/ssl/acme/private/<some domain>/privkey.pem;

все - теперь можно скрипт вставить в cron и добавить релоад nginx

	/usr/local/bin/acme-client -vvvmnN <some domain> && /etc/init.d/nginx reload

zabbix-agent 
 просто автоматизация установки агента с моими настройками
