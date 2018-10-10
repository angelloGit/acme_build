!/bin/sh

apt install g++ git automake libbsd-dev autogen libtool make pkg-config

git clone https://github.com/libressl-portable/portable
git clone https://github.com/kristapsdz/acme-client-portable

cd portable
./autogen.sh
./configure
make
make install
cd ../
ldconfig /usr/local/lib

cd acme-client-portable

patch <<__EOFF
--- main.c.org<>2018-10-09 10:20:28.898377975 +0200
+++ main.c<---->2018-10-09 10:21:25.846963566 +0200
@@ -33,7 +33,7 @@
 #include "extern.h"
 
 #define URL_AGREE "https://letsencrypt.org" \
-		  "/documents/LE-SA-v1.1.1-August-1-2016.pdf"
+		  "/documents/LE-SA-v1.2-November-15-2017.pdf"
 #define SSL_DIR "/etc/ssl/acme"
 #define SSL_PRIV_DIR "/etc/ssl/acme/private"
 #define ETC_DIR "/etc/acme"
__EOFF


make -f GNUmakefile

make -f GNUmakefile install

mkdir /etc/acme
mkdir -p /etc/ssl/acme/private
mkdir /var/empty

cp /usr/local/etc/ssl/cert.pem /etc/ssl/cert.pem

mkdir /var/www/acme
echo 'it works' >> /var/www/acme/index.html

cat /etc/nginx/conf.d/acme <<__EOFF
location /.well-known/acme-challenge {
    alias /var/www/acme;
}
__EOFF
