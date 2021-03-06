#!/bin/bash
CSYNC2_VERSION="2.0"
CSYNC2_RPM_ITER="5.el6"

yum install librsync gnutls sqlite librsync-devel gnutls-devel sqlite-devel
rm -rf csync2-*
rm -f nDeploy-csync2-pkg/usr/sbin/csync2*
rm -f nDeploy-csync2-pkg/*.rpm
wget http://oss.linbit.com/csync2/csync2-${CSYNC2_VERSION}.tar.gz
tar -xvzf csync2-${CSYNC2_VERSION}.tar.gz
cd csync2-${CSYNC2_VERSION}
./configure --prefix=/usr --sysconfdir=/etc/csync2 --localstatedir=/var
make install DESTDIR=../nDeploy-csync2-pkg
cd ../nDeploy-csync2-pkg
mkdir -p var/backups/csync2
mkdir -p var/lib/csync2
fpm -s dir -t rpm -C ../nDeploy-csync2-pkg --vendor "Anoop P Alias" --version ${CSYNC2_VERSION} --iteration ${CSYNC2_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com -e --description "nDeploy custom csync2 package" --url http://anoopalias.github.io/XtendWeb/ --conflicts csync2 -d xinetd -d librsync -d gnutls -d sqlite -d sqlite-devel --after-install ../after_csync2_install --before-remove ../after_csync2_uninstall --name csync2-nDeploy .
rsync -av *.rpm root@gnusys.net:/usr/share/nginx/html/CentOS/6/x86_64/
