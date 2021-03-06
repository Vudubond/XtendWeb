#!/bin/bash
#Author: Anoop P Alias

##Vars
#expecting 6/7 as the first arg to this scripts
#no sanitation is done as this would be mostly used by a person who knows what he is doing
OSVERSION=$1
OPENRESTY_VERSION="1.11.2.3"
OPENRESTY_RPM_ITER="2.el${OSVERSION}"
NPS_VERSION="1.11.33.4"
MY_RUBY_VERSION="2.3.1"
PASSENGER_VERSION="5.1.4"
NAXSI_VERSION="http2"
PS_NGX_EXTRA_FLAGS="--with-cc=/opt/rh/devtoolset-2/root/usr/bin/gcc"
OPENSSL_VERSION="1.0.2k"
LIBRESSL_VERSION="2.5.2"
PCRE_VERSION="8.40"
ZLIB_VERSION="1.2.11"



rm -rf nginx-module-*
rm -rf nginx-pkg
rm -rf openresty-${OPENRESTY_VERSION}*
mkdir -p nginx-pkg/etc/nginx/{modules,modules.d,modules.debug,modules.debug.d,conf.auto}
mkdir -p nginx-pkg/usr/nginx/scripts
mkdir -p nginx-pkg/var/cache/nginx/ngx_pagespeed
mkdir -p nginx-pkg/var/log/nginx
mkdir -p nginx-pkg/var/run

#Create the folders
for module in brotli geoip pagespeed passenger
do
  mkdir -p nginx-module-${module}-pkg/etc/nginx/{modules,modules.d,modules.debug,modules.debug.d,conf.auto,conf.d}
  mkdir -p nginx-module-${module}-pkg/usr/nginx/scripts
done

yum --enablerepo=ndeploy -y install rpm-build libcurl-devel git xz-devel GeoIP-devel
if [ ${OSVERSION} -eq 6 ];then
  rpm --import https://linux.web.cern.ch/linux/scientific6/docs/repository/cern/slc6X/i386/RPM-GPG-KEY-cern
  wget -O /etc/yum.repos.d/slc6-devtoolset.repo https://linux.web.cern.ch/linux/scientific6/docs/repository/cern/devtoolset/slc6-devtoolset.repo
  yum install devtoolset-2-gcc-c++ devtoolset-2-binutils
  rsync -a --exclude 'usr/lib' --exclude 'etc/nginx/conf.d/modsecurity*' --exclude 'etc/nginx/naxsi.d/*' --exclude 'usr/nginx/scripts/*' --exclude 'etc/nginx/conf.d/naxsi_*' --exclude 'etc/nginx/conf.d/brotli.conf' --exclude 'etc/nginx/conf.d/pagespeed.conf' --exclude 'etc/nginx/conf.d/pagespeed_passthrough.conf' --exclude 'etc/nginx/fastcgi_params_geoip' --exclude 'etc/nginx/conf.auto/*' --exclude 'etc/nginx/modules.debug/*' --exclude 'etc/nginx/modules.debug.d/*' --exclude 'etc/nginx/modules/*' --exclude 'etc/nginx/modules.d/*' nginx-pkg-64-common/ nginx-pkg/
else
  rsync -a --exclude 'etc/rc.d' --exclude 'etc/nginx/conf.d/modsecurity*' --exclude 'etc/nginx/naxsi.d/*' --exclude 'usr/nginx/scripts/*' --exclude 'etc/nginx/conf.d/naxsi_*' --exclude 'etc/nginx/conf.d/brotli.conf' --exclude 'etc/nginx/conf.d/pagespeed.conf' --exclude 'etc/nginx/conf.d/pagespeed_passthrough.conf' --exclude 'etc/nginx/fastcgi_params_geoip' --exclude 'etc/nginx/conf.auto/*' --exclude 'etc/nginx/modules.debug/*' --exclude 'etc/nginx/modules.debug.d/*' --exclude 'etc/nginx/modules/*' --exclude 'etc/nginx/modules.d/*' nginx-pkg-64-common/ nginx-pkg/
fi


gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | sudo bash -s stable --ruby=${MY_RUBY_VERSION}
. /usr/local/rvm/scripts/rvm
rvm use ruby-${MY_RUBY_VERSION}
echo ${MY_RUBY_VERSION}
/usr/local/rvm/rubies/ruby-${MY_RUBY_VERSION}/bin/gem install passenger -v ${PASSENGER_VERSION}
/usr/local/rvm/rubies/ruby-${MY_RUBY_VERSION}/bin/gem install fpm

wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz
tar -xvzf openresty-${OPENRESTY_VERSION}.tar.gz
cd openresty-${OPENRESTY_VERSION}/bundle


# Pagespeed and brotli from google
wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
tar -xzvf ${NPS_VERSION}.tar.gz
cd ..

git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli && git submodule update --init && cd ..

cd ..

# LibreSSL , PCRE and ZLIB all latest versions

# OpenSSL
wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar -zxf openssl-${OPENSSL_VERSION}.tar.gz

# LibreSSL
# wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz
# tar -zxf libressl-${LIBRESSL_VERSION}.tar.gz
# cd libressl-${LIBRESSL_VERSION}
# LIBRESSL_INSTALL_PATH=$(pwd)/.openssl
# ./configure LDFLAGS=-lrt --prefix=${LIBRESSL_INSTALL_PATH} && make install-strip
# cd ..

# PCRE
wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz
tar -zxf pcre-${PCRE_VERSION}.tar.gz

# ZLIB
wget http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
tar -zxf zlib-${ZLIB_VERSION}.tar.gz


if [ ${OSVERSION} -eq 6 ];then
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --with-ipv6 --modules-path=/etc/nginx/modules --with-pcre=./pcre-${PCRE_VERSION} --with-pcre-jit --with-zlib=./zlib-${ZLIB_VERSION} --with-openssl=./openssl-${OPENSSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=../ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=../ngx_brotli --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E -lrt"
else
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --with-ipv6 --modules-path=/etc/nginx/modules --with-pcre=./pcre-${PCRE_VERSION} --with-pcre-jit --with-zlib=./zlib-${ZLIB_VERSION} --with-openssl=./openssl-${OPENSSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=../ngx_pagespeed-release-${NPS_VERSION}-beta --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=../ngx_brotli --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E"
fi
make DESTDIR=$(pwd)/tempostrip install
strip --strip-debug ./tempostrip/usr/sbin/nginx
rsync -a tempostrip/usr/sbin ../nginx-pkg/usr/
strip --strip-debug ./tempostrip/etc/nginx/modules/*.so

if [ ${OSVERSION} -eq 6 ];then
./configure --with-debug --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --with-ipv6 --modules-path=/etc/nginx/modules --with-pcre=./pcre-${PCRE_VERSION} --with-pcre-jit --with-zlib=./zlib-${ZLIB_VERSION} --with-openssl=./openssl-${OPENSSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=../ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=../ngx_brotli --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E -lrt"
else
./configure --with-debug --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --with-ipv6 --modules-path=/etc/nginx/modules --with-pcre=./pcre-${PCRE_VERSION} --with-pcre-jit --with-zlib=./zlib-${ZLIB_VERSION} --with-openssl=./openssl-${OPENSSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=../ngx_pagespeed-release-${NPS_VERSION}-beta --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=../ngx_brotli --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E"
fi
make DESTDIR=$(pwd)/tempo install
rsync -a tempo/usr/sbin/nginx ../nginx-pkg/usr/sbin/nginx-debug

#Copy resty stuff
rsync -a tempostrip/etc/nginx/bin tempostrip/etc/nginx/lua* tempostrip/etc/nginx/pod tempostrip/etc/nginx/site tempostrip/etc/nginx/resty* ../nginx-pkg/etc/nginx/

rsync -a ../nginx-pkg-64-common/etc/nginx/fastcgi_params_geoip ../nginx-module-geoip-pkg/etc/nginx/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/pagespeed.conf ../nginx-module-pagespeed-pkg/etc/nginx/conf.d/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/pagespeed_passthrough.conf ../nginx-module-pagespeed-pkg/etc/nginx/conf.d/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/brotli.conf ../nginx-module-brotli-pkg/etc/nginx/conf.d/

for module in brotli geoip pagespeed passenger
do
  rsync -a tempostrip/etc/nginx/modules/ngx_http_${module}* ../nginx-module-${module}-pkg/etc/nginx/modules/
  rsync -a tempo/etc/nginx/modules/ngx_http_${module}* ../nginx-module-${module}-pkg/etc/nginx/modules.debug/
  if [ -f ../nginx-pkg-64-common/etc/nginx/conf.auto/${module}.conf ] ; then
    rsync -a ../nginx-pkg-64-common/etc/nginx/conf.auto/${module}.conf ../nginx-module-${module}-pkg/etc/nginx/conf.auto/
  fi
  rsync -a ../nginx-pkg-64-common/etc/nginx/modules.d/${module}.load ../nginx-module-${module}-pkg/etc/nginx/modules.d/
  rsync -a ../nginx-pkg-64-common/etc/nginx/modules.debug.d/${module}.load ../nginx-module-${module}-pkg/etc/nginx/modules.debug.d/
done
rsync -a tempostrip/etc/nginx/modules/ngx_pagespeed.so ../nginx-module-pagespeed-pkg/etc/nginx/modules/
rsync -a tempo/etc/nginx/modules/ngx_pagespeed.so ../nginx-module-pagespeed-pkg/etc/nginx/modules.debug/

rsync -a ../nginx-pkg-64-common/usr/nginx/scripts/nginx-passenger* ../nginx-module-passenger-pkg/usr/nginx/scripts/

sed -i "s/RUBY_VERSION/$MY_RUBY_VERSION/g" ../nginx-module-passenger-pkg/etc/nginx/conf.auto/passenger.conf
sed -i "s/PASSENGER_VERSION/$PASSENGER_VERSION/g" ../nginx-module-passenger-pkg/etc/nginx/conf.auto/passenger.conf
sed -i "s/RUBY_VERSION/$MY_RUBY_VERSION/g" ../nginx-module-passenger-pkg/usr/nginx/scripts/nginx-passenger-setup.sh
sed -i "s/PASSENGER_VERSION/$PASSENGER_VERSION/g" ../nginx-module-passenger-pkg/usr/nginx/scripts/nginx-passenger-setup.sh

rsync -a /usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/buildout ../nginx-module-passenger-pkg/usr/nginx/
cd ../nginx-pkg

fpm -s dir -t rpm -C ../nginx-pkg --vendor "Anoop P Alias" --version ${OPENRESTY_VERSION} --iteration ${OPENRESTY_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com --description "nDeploy custom nginx package" --url http://anoopalias.github.io/XtendWeb/ --conflicts nginx --conflicts nginx-nDeploy --after-install ../after_nginx_install --before-remove ../after_nginx_uninstall --name openresty-nDeploy .
rsync -a openresty-nDeploy-* root@gnusys.net:/usr/share/nginx/html/CentOS/${OSVERSION}/x86_64/

for module in brotli geoip pagespeed passenger
do
  cd ../nginx-module-${module}-pkg
  if [ ${module} == "brotli" ];then
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${OPENRESTY_VERSION} --iteration ${OPENRESTY_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com --description "nDeploy custom openresty-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts openresty-module-${module} --conflicts nginx-module-${module} -d openresty-nDeploy --name openresty-nDeploy-module-${module} .
  elif [ ${module} == "geoip" ];then
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${OPENRESTY_VERSION} --iteration ${OPENRESTY_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com --description "nDeploy custom openresty-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts openresty-module-${module} --conflicts nginx-module-${module} -d GeoIP -d openresty-nDeploy --name openresty-nDeploy-module-${module} .
  elif [ ${module} == "pagespeed" ];then
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${OPENRESTY_VERSION} --iteration ${OPENRESTY_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com --description "nDeploy custom openresty-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts openresty-module-${module} --conflicts nginx-module-${module} -d memcached -d openresty-nDeploy --name openresty-nDeploy-module-${module} .
  else
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${OPENRESTY_VERSION} --iteration ${OPENRESTY_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com --description "nDeploy custom openresty-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts openresty-module-${module} --conflicts nginx-module-${module} -d openresty-nDeploy --name openresty-nDeploy-module-${module} .
  fi
  rsync -a openresty-nDeploy-* root@gnusys.net:/usr/share/nginx/html/CentOS/${OSVERSION}/x86_64/
done
