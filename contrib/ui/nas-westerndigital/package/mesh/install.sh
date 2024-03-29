#!/bin/sh

INST_PATH=/mnt/HD/HD_a2/Nas_Prog/mesh
MESH_PACKAGE_LOG=/var/log/mesh.log
echo "install.sh called" >> "$MESH_PACKAGE_LOG"

path_src="$1"
path_dst="$2"

rm -rf "$INST_PATH"
mv "$path_src" "$path_dst"
#LOG_SYMLINK
ln -s "$INST_PATH"/var/log/mesh.log "$INST_PATH"/www/log

echo "install.sh: setting permissions to '$path_dst/mesh'" >> "$MESH_PACKAGE_LOG"
chown -R nobody:share "$path_dst/mesh"

ln -fs "$INST_PATH"/apache-mesh.conf /usr/local/apache2/conf/extra
ln -fs "$INST_PATH"/apache-mesh.conf /usr/local/apache2/conf/sites-enabled

( sleep 1 ; /usr/sbin/apache restart web ) &

if [ ! -d /var/www/mesh ] ; then
    ln -sf $INST_PATH/ui /var/www/mesh_app
fi

#( sleep 2 ; /usr/sbin/apache restart web ) &
