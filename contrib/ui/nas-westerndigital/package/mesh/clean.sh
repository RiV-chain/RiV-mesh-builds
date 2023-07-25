#!/bin/sh

MESH_PACKAGE_LOG=/var/log/mesh.log
echo "clean.sh called" >> "$MESH_PACKAGE_LOG"

rm -f /usr/bin/mesh
rm -f /usr/bin/meshctl


rm -f /usr/local/apache2/conf/extra/apache-mesh.conf
rm -f /usr/local/apache2/conf/sites-enabled/apache-mesh.conf
rm -rf /var/www/mesh_app 2>&1 >/dev/null
