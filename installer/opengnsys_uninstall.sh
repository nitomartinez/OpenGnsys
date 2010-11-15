#!/bin/bash
# Desinstalación de OpenGnSys.


# Variables.
OPENGNSYS="/opt/opengnsys"    # Directorio de OpenGnSys
OGIMG="images"                # Directorio de imágenes del repositorio
MYSQLROOT="passwordroot"      # Clave de root de MySQL
DATABASE="ogAdmBD"            # Base de datos de administración
OLDDATABASE="ogBDAdmin"       # Antigua base de datos
DBUSER="usuog"                # Usuario de acceso a la base de datos

# Parar servicio.
echo "Uninstalling OpenGnSys services."
if [ -x /etc/init.d/opengnsys ]; then
    /etc/init.d/opengnsys stop
    update-rc.d -f opengnsys remove
fi
# Eliminar bases de datos.
echo "Erasing OpenGnSys database."
DROP=1
if ! mysql -u root -p"$MYSQLROOT" <<<"quit" 2>/dev/null; then
    stty -echo
    read -p  "- Please, insert MySQL root password: " MYSQLROOT
    echo ""
    stty echo
    if ! mysql -u root -p"$MYSQLROOT" <<<"quit" 2>/dev/null; then
	DROP=0
	echo "Warning: database not erased."
    fi
fi
if test $DROP; then
    mysql -u root -p"$MYSQLROOT" <<<"DROP DATABASE $OLDDATABASE;" 2>/dev/null
    mysql -u root -p"$MYSQLROOT" <<<"DROP DATABASE $DATABASE;" 2>/dev/null
    mysql -u root -p"$MYSQLROOT" <<<"DROP USER '$DBUSER';" 2>/dev/null
    mysql -u root -p"$MYSQLROOT" <<<"DROP USER '$DBUSER'@'localhost';" 2>/dev/null
fi
# Eliminar ficheros.
echo "Deleting OpenGnSys files."
for dir in $OPENGNSYS/*; do
    if [ "$dir" != "$OPENGNSYS/$OGIMG" ]; then
        rm -fr "$dir"
    fi
done
rm -f /etc/init.d/opengnsys /etc/default/opengnsys
# Tareas manuales a realizar después de desinstalar.
echo "Manual tasks:"
echo "- You may stop or uninstall manually all other services"
echo "     (DHCP, PXE, TFTP, NFS, Apache, MySQL)."
echo "- Delete repository directory \"$OGIMG\""

