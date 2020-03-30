#!/bin/bash

#####################################################################
####### Script instalador OpenGnsys
####### Autor: Luis Guillén <lguillen@unizar.es>
#####################################################################


####  AVISO: Puede editar configuración de acceso por defecto.
####  WARNING: Edit default access configuration if you wish.
DEFAULT_MYSQL_ROOT_PASSWORD="passwordroot"	# Clave por defecto root de MySQL
DEFAULT_OPENGNSYS_DB_USER="admin"		# Usuario por defecto de acceso a la base de datos
DEFAULT_OPENGNSYS_DB_PASSWD="admin"		# Clave por defecto de acceso a la base de datos
DEFAULT_OPENGNSYS_CLIENT_PASSWD="og"		# Clave por defecto de acceso del cliente	

# Sólo ejecutable por usuario root
if [ "$(whoami)" != 'root' ]; then
        echo "ERROR: this program must run under root privileges!!"
        exit 1
fi

echo -e "\\nOpenGnsys Installation"
echo "=============================="

# Clave root de MySQL
while : ; do
	echo -n -e "\\nEnter root password for MySQL (${DEFAULT_MYSQL_ROOT_PASSWORD}): ";
	read -r MYSQL_ROOT_PASSWORD
	if [ -n "${MYSQL_ROOT_PASSWORD//[a-zA-Z0-9]/}" ]; then # Comprobamos que sea un valor alfanumerico
		echo -e "\\aERROR: Must be alphanumeric, try again..."
	else
		# Si esta vacio ponemos el valor por defecto
		MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-$DEFAULT_MYSQL_ROOT_PASSWORD}"
		break
	fi
done

# Usuario de acceso a la base de datos
while : ; do
	echo -n -e "\\nEnter username for OpenGnsys console (${DEFAULT_OPENGNSYS_DB_USER}): "
	read -r OPENGNSYS_DB_USER
	if [ -n "${OPENGNSYS_DB_USER//[a-zA-Z0-9]/}" ]; then # Comprobamos que sea un valor alfanumerico
		echo -e "\\aERROR: Must be alphanumeric, try again..."
	else
		# Si esta vacio ponemos el valor por defecto
		OPENGNSYS_DB_USER="${OPENGNSYS_DB_USER:-$DEFAULT_OPENGNSYS_DB_USER}"
		break
	fi
done

# Clave de acceso a la base de datos
while : ; do
	echo -n -e "\\nEnter password for OpenGnsys console (${DEFAULT_OPENGNSYS_DB_PASSWD}): "
	read -r OPENGNSYS_DB_PASSWD
	if [ -n "${OPENGNSYS_DB_PASSWD//[a-zA-Z0-9]/}" ]; then # Comprobamos que sea un valor alfanumerico
		echo -e "\\aERROR: Must be alphanumeric, try again..."
	else
		# Si esta vacio ponemos el valor por defecto
		OPENGNSYS_DB_PASSWD="${OPENGNSYS_DB_PASSWD:-$DEFAULT_OPENGNSYS_DB_PASSWD}"
		break
	fi
done

# Clave de acceso del cliente
while : ; do
	echo -n -e "\\nEnter root password for OpenGnsys client (${DEFAULT_OPENGNSYS_CLIENT_PASSWD}): "
	read -r OPENGNSYS_CLIENT_PASSWD
	if [ -n "${OPENGNSYS_CLIENT_PASSWD//[a-zA-Z0-9]/}" ]; then # Comprobamos que sea un valor alfanumerico
		echo -e "\\aERROR: Must be alphanumeric, try again..."
	else
		# Si esta vacio ponemos el valor por defecto
		OPENGNSYS_CLIENT_PASSWD="${OPENGNSYS_CLIENT_PASSWD:-$DEFAULT_OPENGNSYS_CLIENT_PASSWD}"
		break
	fi
done

# Selección de clientes ogLive para descargar.
while : ; do
	echo -e "\\nChoose ogLive client to install."
	echo -e "1) Kernel 4.13, 64-bit, EFI-compatible"
	echo -e "2) Kernel 3.2, 32-bit"
	echo -e "3) Both"
	echo -n -e "Please, type a valid number (1): "
	read -r OPT
	case "$OPT" in
		1|"")	OGLIVE="ogLive-xenial-4.13.0-17-generic-amd64-r5520.iso"
			break ;;
		2)	OGLIVE="ogLive-precise-3.2.0-23-generic-r5159.iso"
			break ;;
		3)	OGLIVE="ogLive-xenial-4.13.0-17-generic-amd64-r5520.iso ogLive-precise-3.2.0-23-generic-r5159.iso";
			break ;;
		*)	echo -e "\\aERROR: unknown option, try again."
	esac
done

echo -e "\\n=============================="

# Comprobar si se ha descargado el paquete comprimido (REMOTE=0) o sólo el instalador (REMOTE=1).
PROGRAMDIR=$(readlink -e "$(dirname "$0")")
PROGRAMNAME=$(basename "$0")
OPENGNSYS_SERVER="opengnsys.es"
DOWNLOADURL="https://$OPENGNSYS_SERVER/trac/downloads"
if [ -d "$PROGRAMDIR/../installer" ]; then
	REMOTE=0
else
	REMOTE=1
fi
BRANCH="devel"
CODE_URL="https://codeload.github.com/opengnsys/OpenGnsys/zip/$BRANCH"
API_URL="https://api.github.com/repos/opengnsys/OpenGnsys/branches/$BRANCH"

WORKDIR=/tmp/opengnsys_installer
mkdir -p $WORKDIR

# Directorio destino de OpenGnsys.
INSTALL_TARGET=/opt/opengnsys
PATH=$PATH:$INSTALL_TARGET/bin

# Registro de incidencias.
OGLOGFILE=$INSTALL_TARGET/log/${PROGRAMNAME%.sh}.log
LOG_FILE=/tmp/$(basename $OGLOGFILE)

# Usuario del cliente para acceso remoto.
OPENGNSYS_CLIENT_USER="opengnsys"

# Nombre de la base datos.
OPENGNSYS_DATABASE="opengnsys"


#####################################################################
####### Funciones de configuración
#####################################################################

# Generar variables de configuración del instalador
# Variables globales:
# - OSDISTRIB, OSVERSION - tipo y versión de la distribución GNU/Linux
# - PREREQS, DEPENDENCIES - arrays de prerrequisitos y dependencias que deben estar instaladas
# - UPDATEPKGLIST, INSTALLPKGS, CHECKPKGS - comandos para gestión de paquetes
# - INSTALLEXTRADEPS - instalar dependencias no incluidas en la distribución
# - STARTSERVICE, ENABLESERVICE - iniciar y habilitar un servicio
# - STOPSERVICE, DISABLESERVICE - parar y deshabilitar un servicio
# - APACHESERV, APACHECFGDIR, APACHESITESDIR, APACHEUSER, APACHEGROUP - servicio y configuración de Apache
# - APACHEENABLEMODS, APACHEENABLESSL, APACHEMAKECERT - habilitar módulos y certificado SSL
# - APACHEENABLEOG, APACHEOGSITE, - habilitar sitio web de OpenGnsys
# - PHPFPMSERV - servicio PHP FastCGI Process Manager para Apache
# - INETDSERV - servicio Inetd
# - DHCPSERV, DHCPCFGDIR - servicio y configuración de DHCP
# - MYSQLSERV, TMPMYCNF - servicio MySQL y fichero temporal con credenciales de acceso
# - MARIADBSERV - servicio MariaDB (sustituto de MySQL en algunas distribuciones)
# - RSYNCSERV, RSYNCCFGDIR - servicio y configuración de Rsync
# - SAMBASERV, SAMBACFGDIR - servicio y configuración de Samba
# - TFTPSERV, TFTPCFGDIR - servicio y configuración de TFTP/PXE
function autoConfigure()
{
# Detectar sistema operativo del servidor (compatible con fichero os-release y con LSB).
if [ -f /etc/os-release ]; then
	source /etc/os-release
	OSDISTRIB="$ID"
	OSVERSION="$VERSION_ID"
else
	OSDISTRIB=$(lsb_release -is 2>/dev/null)
	OSVERSION=$(lsb_release -rs 2>/dev/null)
fi
# Convertir distribución a minúsculas y obtener solo el 1er número de versión.
OSDISTRIB="${OSDISTRIB,,}"
OSVERSION="${OSVERSION%%.*}"

# Configuración según la distribución GNU/Linux (usar minúsculas).
case "$OSDISTRIB" in
	ubuntu|debian|linuxmint)
		PREREQS=( curl software-properties-common )
		DEPENDENCIES=( subversion apache2 php php-ldap php-fpm mysql-server php-mysql isc-dhcp-server bittorrent tftp-hpa tftpd-hpa xinetd build-essential g++-multilib libmysqlclient-dev wget doxygen graphviz bittornado ctorrent samba rsync unzip netpipes debootstrap schroot squashfs-tools btrfs-tools procps arp-scan realpath php-curl gettext moreutils jq udpcast libev-dev shim-signed grub-efi-amd64-signed git php-mbstring php-xml nodejs debhelper )
		UPDATEPKGLIST="apt-get update"
		INSTALLPKG="apt-get -y install"
		CHECKPKG="dpkg -s \$package 2>/dev/null | grep Status | grep -qw install"
		if which service &>/dev/null; then
			STARTSERVICE="eval service \$service restart"
			STOPSERVICE="eval service \$service stop"
		else
			STARTSERVICE="eval /etc/init.d/\$service restart"
			STOPSERVICE="eval /etc/init.d/\$service stop"
		fi
		ENABLESERVICE="eval update-rc.d \$service defaults"
		DISABLESERVICE="eval update-rc.d \$service disable"
		APACHESERV=apache2
		APACHECFGDIR=/etc/apache2
		APACHESITESDIR=sites-available
		APACHEOGSITE=opengnsys
		APACHEUSER="www-data"
		APACHEGROUP="www-data"
		APACHEENABLEMODS="a2enmod ssl rewrite proxy_fcgi actions alias"
		APACHEENABLESSL="a2ensite default-ssl"
		APACHEENABLEOG="a2ensite $APACHEOGSITE"
		APACHEMAKECERT="make-ssl-cert generate-default-snakeoil --force-overwrite"
		DHCPSERV=isc-dhcp-server
		DHCPCFGDIR=/etc/dhcp
		INETDSERV=xinetd
		INETDCFGDIR=/etc/xinetd.d
		MYSQLSERV=mysql
		MARIADBSERV=mariadb
		PHPFPMSERV=php-fpm
		RSYNCSERV=rsync
		RSYNCCFGDIR=/etc
		SAMBASERV=smbd
		SAMBACFGDIR=/etc/samba
		TFTPCFGDIR=/var/lib/tftpboot
		;;
	fedora|centos)
		PREREQS=( curl )
		DEPENDENCIES=( subversion httpd mod_ssl php-ldap php-fpm mysql-server mysql-devel mysql-devel.i686 php-mysql dhcp tftp-server tftp xinetd binutils gcc gcc-c++ glibc-devel glibc-devel.i686 glibc-static glibc-static.i686 libstdc++-devel.i686 make wget doxygen graphviz ctorrent samba samba-client rsync unzip debootstrap schroot squashfs-tools python-crypto arp-scan procps-ng gettext moreutils jq net-tools udpcast libev-devel shim-x64 grub2-efi-x64 grub2-efi-x64-modules http://ftp.altlinux.org/pub/distributions/ALTLinux/5.1/branch/$(arch)/RPMS.classic/netpipes-4.2-alt1.$(arch).rpm )
		[ "$OSDISTRIB" == "centos" ] && UPDATEPKGLIST="yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$OSVERSION.noarch.rpm http://rpms.remirepo.net/enterprise/remi-release-$OSVERSION.rpm"
		INSTALLEXTRADEPS=( 'pushd /tmp; wget -t3 http://ftp.acc.umu.se/mirror/bittornado/BitTornado-0.3.18.tar.gz && tar xvzf BitTornado-0.3.18.tar.gz && cd BitTornado-CVS && python setup.py install && ln -fs btlaunchmany.py /usr/bin/btlaunchmany && ln -fs bttrack.py /usr/bin/bttrack; popd' )
		INSTALLPKG="yum install -y libstdc++ libstdc++.i686"
		CHECKPKG="rpm -q --quiet \$package"
		SYSTEMD=$(which systemctl 2>/dev/null)
		if [ -n "$SYSTEMD" ]; then
			STARTSERVICE="eval systemctl start \$service.service"
			STOPSERVICE="eval systemctl stop \$service.service"
			ENABLESERVICE="eval systemctl enable \$service.service"
			DISABLESERVICE="eval systemctl disable \$service.service"
		else
			STARTSERVICE="eval service \$service start"
			STOPSERVICE="eval service \$service stop"
			ENABLESERVICE="eval chkconfig \$service on"
			DISABLESERVICE="eval chkconfig \$service off"
		fi
		APACHESERV=httpd
		APACHECFGDIR=/etc/httpd/conf.d
		APACHEOGSITE=opengnsys.conf
		APACHEUSER="apache"
		APACHEGROUP="apache"
		APACHEREWRITEMOD="sed -i '/rewrite/s/^#//' $APACHECFGDIR/../*.conf"
		DHCPSERV=dhcpd
		DHCPCFGDIR=/etc/dhcp
		INETDSERV=xinetd
		INETDCFGDIR=/etc/xinetd.d
		MYSQLSERV=mysqld
		MARIADBSERV=mariadb
		PHPFPMSERV=php-fpm
		RSYNCSERV=rsync
		RSYNCCFGDIR=/etc
		SAMBASERV=smb
		SAMBACFGDIR=/etc/samba
		TFTPSERV=tftp
		TFTPCFGDIR=/var/lib/tftpboot
		;;
	"") 	echo "ERROR: Unknown Linux distribution, please install \"lsb_release\" command."
		exit 1 ;;
	*) 	echo "ERROR: Distribution not supported by OpenGnsys."
		exit 1 ;;
esac
# Instalar Composer y Angular-CLI.
INSTALLEXTRADEPS=( ${INSTALLEXTRADEPS[@]} \
		   'if [ ! -f /usr/local/bin/composer.phar ]; then php -r "copy(\"https://getcomposer.org/installer\", \"/tmp/composer-setup.php\");"; php /tmp/composer-setup.php --install-dir=/usr/local/bin; rm -f /tmp/composer-setup.php; else /usr/local/bin/composer.phar self-update; fi' \
		   'npm install -g @angular/cli@6.2.3' )

# Fichero de credenciales de acceso a MySQL.
TMPMYCNF=/tmp/.my.cnf.$$
}


# Modificar variables de configuración tras instalar paquetes del sistema.
function autoConfigurePost()
{
# Configuraciones específicas para Samba y TFTP en Debian 6.
[ -z "$SYSTEMD" -a ! -e /etc/init.d/$SAMBASERV ] && SAMBASERV=samba
[ ! -e $TFTPCFGDIR ] && TFTPCFGDIR=/srv/tftp
}


# Cargar lista de paquetes del sistema y actualizar algunas variables de configuración
# dependiendo de la versión instalada.
function updatePackageList()
{
local DHCPVERSION PHP7VERSION

# Si es necesario, actualizar la lista de paquetes disponibles e instalar prerrequisitos.
[ -n "$UPDATEPKGLIST" ] && eval $UPDATEPKGLIST
[ ${#PREREQS[@]} -gt 0 ] && eval $INSTALLPKG ${PREREQS[@]}

# Configuración personallizada de algunos paquetes.
case "$OSDISTRIB" in
	ubuntu|linuxmint)	# Postconfiguación personalizada para Ubuntu.
		# Instalar prerrequisitos.
		# Configuración para DHCP v3.
		DHCPVERSION=$(apt-cache show $(apt-cache pkgnames|egrep "dhcp.?-server$") | \
			      awk '/Version/ {print substr($2,1,1);}' | \
			      sort -n | tail -1)
		if [ $DHCPVERSION = 3 ]; then
			DEPENDENCIES=( ${DEPENDENCIES[@]/isc-dhcp-server/dhcp3-server} )
			DHCPSERV=dhcp3-server
			DHCPCFGDIR=/etc/dhcp3
		fi
		# Configuración para PHP 7 en Ubuntu.
		if [ -z "$(apt-cache pkgnames php7)" ]; then
			add-apt-repository -y ppa:ondrej/php
			eval $UPDATEPKGLIST
			PHP7VERSION=$(apt-cache pkgnames php7. | sort | tail -1)
			PHPFPMSERV="${PHP7VERSION}-fpm"
			DEPENDENCIES=( ${DEPENDENCIES[@]//php/$PHP7VERSION} )
		fi
		# Adaptar dependencias para libmysqlclient.
		[ -z "$(apt-cache pkgnames libmysqlclient-dev)" ] && [ -n "$(apt-cache pkgnames libmysqlclient15)" ] && DEPENDENCIES=( ${DEPENDENCIES[@]//libmysqlclient-dev/libmysqlclient15} )
		# Paquete correcto para realpath.
		[ -z "$(apt-cache pkgnames realpath)" ] && DEPENDENCIES=( ${DEPENDENCIES[@]//realpath/coreutils} )
		# Instalar NodeJS.
		curl -sL https://deb.nodesource.com/setup_10.x | bash -
		;;
	centos)	# Postconfiguación personalizada para CentOS.
		# Configuración para PHP 7.
		PHP7VERSION=$(yum list -q php7\* 2>/dev/null | awk -F. '/^php/ {print $1; exit;}')
		PHPFPMSERV="${PHP7VERSION}-${PHPFPMSERV}"
		DEPENDENCIES=( ${PHP7VERSION} ${DEPENDENCIES[@]//php/$PHP7VERSION-php} )
		# Cambios a aplicar a partir de CentOS 7.
		if [ $OSVERSION -ge 7 ]; then
			# Sustituir MySQL por MariaDB.
			DEPENDENCIES=( ${DEPENDENCIES[*]/mysql-/mariadb-} )
			# Instalar ctorrent de EPEL para CentOS 6 (no disponible en CentOS 7).
			DEPENDENCIES=( ${DEPENDENCIES[*]/ctorrent/http://dl.fedoraproject.org/pub/epel/6/$(arch)/Packages/c/ctorrent-1.3.4-14.dnh3.3.2.el6.$(arch).rpm} )
		fi
		# Instalar NodeJS.
		curl -sL https://rpm.nodesource.com/setup_10.x | bash -
		;;
	fedora)	# Postconfiguación personalizada para Fedora. 
		# Incluir paquetes específicos.
		DEPENDENCIES=( ${DEPENDENCIES[@]} btrfs-progs )
		# Sustituir MySQL por MariaDB a partir de Fedora 20.
		[ $OSVERSION -ge 20 ] && DEPENDENCIES=( ${DEPENDENCIES[*]/mysql-/mariadb-} )
		# Instalar NodeJS.
		curl -sL https://rpm.nodesource.com/setup_10.x | bash -
		;;
esac
}


#####################################################################
####### Algunas funciones útiles de propósito general:
#####################################################################

function getDateTime()
{
	date "+%Y%m%d-%H%M%S"
}

# Escribe a fichero y muestra por pantalla
function echoAndLog()
{
	local DATETIME=`getDateTime`
	echo "$1"
	echo "$DATETIME;$SSH_CLIENT;$1" >> $LOG_FILE
}

# Escribe a fichero y muestra mensaje de error
function errorAndLog()
{
	local DATETIME=`getDateTime`
	echo "ERROR: $1"
	echo "$DATETIME;$SSH_CLIENT;ERROR: $1" >> $LOG_FILE
}

# Escribe a fichero y muestra mensaje de aviso
function warningAndLog()
{
	local DATETIME=`getDateTime`
	echo "Warning: $1"
	echo "$DATETIME;$SSH_CLIENT;Warning: $1" >> $LOG_FILE
}

# Comprueba si el elemento pasado en $2 está en el array $1
function isInArray()
{
	if [ $# -ne 2 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local deps
	local is_in_array=1
	local element="$2"

	echoAndLog "${FUNCNAME}(): checking if $2 is in $1"
	eval "deps=( \"\${$1[@]}\" )"

	# Copia local del array del parámetro 1.
	for (( i = 0 ; i < ${#deps[@]} ; i++ )); do
		if [ "${deps[$i]}" = "${element}" ]; then
			echoAndLog "isInArray(): $element found in array"
			is_in_array=0
		fi
	done

	if [ $is_in_array -ne 0 ]; then
		echoAndLog "${FUNCNAME}(): $element NOT found in array"
	fi

	return $is_in_array
}


#####################################################################
####### Funciones de manejo de paquetes Debian
#####################################################################

function checkPackage()
{
	package=$1
	if [ -z $package ]; then
		errorAndLog "${FUNCNAME}(): parameter required"
		exit 1
	fi
	echoAndLog "${FUNCNAME}(): checking if package $package exists"
	eval $CHECKPKG
	if [ $? -eq 0 ]; then
		echoAndLog "${FUNCNAME}(): package $package exists"
		return 0
	else
		echoAndLog "${FUNCNAME}(): package $package doesn't exists"
		return 1
	fi
}

# Recibe array con dependencias
# por referencia deja un array con las dependencias no resueltas
# devuelve 1 si hay alguna dependencia no resuelta
function checkDependencies()
{
	if [ $# -ne 2 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	echoAndLog "${FUNCNAME}(): checking dependences"
	uncompletedeps=0

	# copia local del array del parametro 1
	local deps
	eval "deps=( \"\${$1[@]}\" )"

	declare -a local_notinstalled

	for (( i = 0 ; i < ${#deps[@]} ; i++ ))
	do
		checkPackage ${deps[$i]}
		if [ $? -ne 0 ]; then
			local_notinstalled[$uncompletedeps]=$package
			let uncompletedeps=uncompletedeps+1
		fi
	done

	# relleno el array especificado en $2 por referencia
	for (( i = 0 ; i < ${#local_notinstalled[@]} ; i++ ))
	do
		eval "${2}[$i]=${local_notinstalled[$i]}"
	done

	# retorna el numero de paquetes no resueltos
	echoAndLog "${FUNCNAME}(): dependencies uncompleted: $uncompletedeps"
	return $uncompletedeps
}

# Recibe un array con las dependencias y lo instala
function installDependencies()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi
	echoAndLog "${FUNCNAME}(): installing uncompleted dependencies"

	# copia local del array del parametro 1
	local deps
	eval "deps=( \"\${$1[@]}\" )"

	local string_deps=""
	for (( i = 0 ; i < ${#deps[@]} ; i++ ))
	do
		string_deps="$string_deps ${deps[$i]}"
	done

	if [ -z "${string_deps}" ]; then
		errorAndLog "${FUNCNAME}(): array of dependeces is empty"
		exit 1
	fi

	OLD_DEBIAN_FRONTEND=$DEBIAN_FRONTEND		# Debian/Ubuntu
	export DEBIAN_FRONTEND=noninteractive

	echoAndLog "${FUNCNAME}(): now $string_deps will be installed"
	eval $INSTALLPKG $string_deps
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error installing dependencies"
		return 1
	fi

	DEBIAN_FRONTEND=$OLD_DEBIAN_FRONTEND		# Debian/Ubuntu
	test grep -q "EPEL temporal" /etc/yum.repos.d/epel.repo 2>/dev/null || mv -f /etc/yum.repos.d/epel.repo.rpmnew /etc/yum.repos.d/epel.repo 2>/dev/null	# CentOS/RedHat EPEL

	echoAndLog "${FUNCNAME}(): dependencies installed"
}

# Hace un backup del fichero pasado por parámetro
# deja un -last y uno para el día
function backupFile()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local file="$1"
	local dateymd=`date +%Y%m%d`

	if [ ! -f "$file" ]; then
		warningAndLog "${FUNCNAME}(): file $file doesn't exists"
		return 1
	fi

	echoAndLog "${FUNCNAME}(): making $file backup"

	# realiza una copia de la última configuración como last
	cp -a "$file" "${file}-LAST"

	# si para el día no hay backup lo hace, sino no
	if [ ! -f "${file}-${dateymd}" ]; then
		cp -a "$file" "${file}-${dateymd}"
	fi

	echoAndLog "${FUNCNAME}(): $file backup success"
}

#####################################################################
####### Funciones para el manejo de bases de datos
#####################################################################

# This function set password to root
function mysqlSetRootPassword()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local root_mysql="$1"
	echoAndLog "${FUNCNAME}(): setting root password in MySQL server"
	mysqladmin -u root password "$root_mysql"
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while setting root password in MySQL server"
		return 1
	fi
	echoAndLog "${FUNCNAME}(): root password saved!"
	return 0
}

# Si el servicio mysql esta ya instalado cambia la variable de la clave del root por la ya existente
function mysqlGetRootPassword()
{
	local pass_mysql
	local pass_mysql2
        # Comprobar si MySQL está instalado con la clave de root por defecto.
        if mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<<"quit" 2>/dev/null; then
		echoAndLog "${FUNCNAME}(): Using default mysql root password."
        else
	        stty -echo
	        echo "There is a MySQL service already installed."
	        read -p "Enter MySQL root password: " pass_mysql
	        echo ""
	        read -p "Confrim password:" pass_mysql2
	        echo ""
	        stty echo
	        if [ "$pass_mysql" == "$pass_mysql2" ] ;then
		        MYSQL_ROOT_PASSWORD="$pass_mysql"
		        return 0
	        else
			echo "The keys don't match. Do not configure the server's key,"
	        	echo "transactions in the database will give error."
	        	return 1
	        fi
	fi
}

# comprueba si puede conectar con mysql con el usuario root
function mysqlTestConnection()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local root_password="$1"
	echoAndLog "${FUNCNAME}(): checking connection to mysql..."
	# Componer fichero con credenciales de conexión a MySQL.
 	touch $TMPMYCNF
 	chmod 600 $TMPMYCNF
 	cat << EOT > $TMPMYCNF
[client]
user=root
password=$root_password
EOT
	# Borrar el fichero temporal si termina el proceso de instalación.
	trap "rm -f $TMPMYCNF" 0 1 2 3 6 9 15
 	# Comprobar conexión a MySQL.
 	echo "" | mysql --defaults-extra-file=$TMPMYCNF
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): connection to mysql failed, check root password and if daemon is running!"
		return 1
	else
		echoAndLog "${FUNCNAME}(): connection success"
		return 0
	fi
}

# comprueba si la base de datos existe
function mysqlDbExists()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local database="$1"
	echoAndLog "${FUNCNAME}(): checking if $database exists..."
	echo "show databases" | mysql --defaults-extra-file=$TMPMYCNF | grep "^${database}$"
	if [ $? -ne 0 ]; then
		echoAndLog "${FUNCNAME}():database $database doesn't exists"
		return 1
	else
		echoAndLog "${FUNCNAME}():database $database exists"
		return 0
	fi
}

# Comprueba si la base de datos está vacía.
function mysqlCheckDbIsEmpty()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local database="$1"
	echoAndLog "${FUNCNAME}(): checking if $database is empty..."
	num_tablas=`echo "show tables" | mysql --defaults-extra-file=$TMPMYCNF "${database}" | wc -l`
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error executing query, check database and root password"
		exit 1
	fi

	if [ $num_tablas -eq 0 ]; then
		echoAndLog "${FUNCNAME}():database $database is empty"
		return 0
	else
		echoAndLog "${FUNCNAME}():database $database has tables"
		return 1
	fi

}

# Importa un fichero SQL en la base de datos.
# Parámetros:
# - 1: nombre de la BD.
# - 2: fichero a importar.
# Nota: el fichero SQL puede contener las siguientes palabras reservadas:
# - SERVERIP: se sustituye por la dirección IP del servidor.
# - DBUSER: se sustituye por usuario de conexión a la BD definido en este script.
# - DBPASSWD: se sustituye por la clave de conexión a la BD definida en este script.
function mysqlImportSqlFileToDb()
{
	if [ $# -ne 2 ]; then
		errorAndLog "${FNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local database="$1"
	local sqlfile="$2"
	local tmpfile=$(mktemp)
	local i=0
	local dev=""
	local status
	# Claves aleatorias para acceso a las APIs REST.
	local OPENGNSYS_APIKEY=$(php -r 'echo md5(uniqid(rand(), true));')
	OPENGNSYS_REPOKEY=$(php -r 'echo md5(uniqid(rand(), true));')

	if [ ! -f $sqlfile ]; then
		errorAndLog "${FUNCNAME}(): Unable to locate $sqlfile!!"
		return 1
	fi

	echoAndLog "${FUNCNAME}(): importing SQL file to ${database}..."
	chmod 600 $tmpfile
	for dev in ${DEVICE[*]}; do
		if [ "${DEVICE[i]}" == "$DEFAULTDEV" ]; then
			sed -e "s/SERVERIP/${SERVERIP[i]}/g" \
			    -e "s/DBUSER/$OPENGNSYS_DB_USER/g" \
			    -e "s/DBPASSWORD/$OPENGNSYS_DB_PASSWD/g" \
			    -e "s/APIKEY/$OPENGNSYS_APIKEY/g" \
			    -e "s/REPOKEY/$OPENGNSYS_REPOKEY/g" \
				$sqlfile > $tmpfile
		fi
		let i++
	done
	mysql --defaults-extra-file=$TMPMYCNF --default-character-set=utf8 "${database}" < $tmpfile
	status=$?
	rm -f $tmpfile
	if [ $status -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while importing $sqlfile in database $database"
		return 1
	fi
	echoAndLog "${FUNCNAME}(): file imported to database $database"
	return 0
}

# Crea la base de datos
function mysqlCreateDb()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local database="$1"

	echoAndLog "${FUNCNAME}(): creating database..."
	mysqladmin --defaults-extra-file=$TMPMYCNF create $database
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while creating database $database"
		return 1
	fi
	# Quitar modo ONLY_FULL_GROUP_BY de MySQL (ticket #730).
	mysql --defaults-extra-file=$TMPMYCNF -e "SET GLOBAL sql_mode=(SELECT TRIM(BOTH ',' FROM REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY','')));"

	echoAndLog "${FUNCNAME}(): database $database created"
	return 0
}

# Comprueba si ya está definido el usuario de acceso a la BD.
function mysqlCheckUserExists()
{
if [ $# -ne 1 ]; then
	errorAndLog "${FUNCNAME}(): invalid number of parameters"
	exit 1
fi
local userdb="$1"

echoAndLog "${FUNCNAME}(): checking if $userdb exists..."
if [ "$(mysql --defaults-extra-file=$TMPMYCNF -Nse "SELECT user FROM mysql.user WHERE user='$userdb'")" == "$userdb" ]; then
	echoAndLog "${FUNCNAME}(): user already exists"
	return 0
else
	echoAndLog "${FUNCNAME}(): user doesn't exists"
	return 1
fi
}

# Crea un usuario administrativo para la base de datos
function mysqlCreateAdminUserToDb()
{
	if [ $# -ne 3 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local database="$1"
	local userdb="$2"
	local passdb="$3"

	echoAndLog "${FUNCNAME}(): creating admin user ${userdb} to database ${database}"

	cat > $WORKDIR/create_${database}.sql <<EOF
GRANT USAGE ON *.* TO '${userdb}'@'localhost' IDENTIFIED BY '${passdb}' ;
GRANT ALL PRIVILEGES ON ${database}.* TO '${userdb}'@'localhost' WITH GRANT OPTION ;
FLUSH PRIVILEGES ;
EOF
	mysql --defaults-extra-file=$TMPMYCNF < $WORKDIR/create_${database}.sql
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while creating user in mysql"
		rm -f $WORKDIR/create_${database}.sql
		return 1
	else
		echoAndLog "${FUNCNAME}(): user created ok"
		rm -f $WORKDIR/create_${database}.sql
		return 0
	fi
}


#####################################################################
####### Funciones para la descarga de código
#####################################################################

# Obtiene el código fuente del proyecto desde el repositorio de GitHub.
function downloadCode()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local url="$1"

	echoAndLog "${FUNCNAME}(): downloading code..."

	curl "${url}" -o opengnsys.zip && unzip opengnsys.zip && mv "OpenGnsys-$BRANCH" opengnsys
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error getting OpenGnsys code from $url"
		return 1
	fi
	rm -f opengnsys.zip
	echoAndLog "${FUNCNAME}(): code was downloaded"
	return 0
}


############################################################
###  Detectar red
############################################################

# Comprobar si existe conexión.
function checkNetworkConnection()
{
echoAndLog "${FUNCNAME}(): Checking OpenGnsys server connectivity."
OPENGNSYS_SERVER=${OPENGNSYS_SERVER:-"opengnsys.es"}
curl --connect-timeout 10 -s $OPENGNSYS_SERVER -o /dev/null
}

# Convierte nº de bits (notación CIDR) en máscara de red (gracias a FriedZombie en openwrt.org).
cidr2mask ()
{
	# Number of args to shift, 255..255, first non-255 byte, zeroes
	set -- $[ 5 - ($1 / 8) ] 255 255 255 255 $[ (255 << (8 - ($1 % 8))) & 255 ] 0 0 0
	[ $1 -gt 1 ] && shift $1 || shift
	echo ${1-0}.${2-0}.${3-0}.${4-0}
}

# Obtener los parámetros de red de la interfaz por defecto.
function getNetworkSettings()
{
	# Arrays globales definidas:
	# - DEVICE:     nombres de dispositivos de red activos.
	# - SERVERIP:   IPs locales del servidor.
	# - NETIP:      IPs de redes.
	# - NETMASK:    máscaras de red.
	# - NETBROAD:   IPs de difusión de redes.
	# - ROUTERIP:   IPs de routers.
	# Otras variables globales:
	# - DEFAULTDEV: dispositivo de red por defecto.
	# - DNSIP:      IP del servidor DNS principal.

	local i=0
	local dev=""

	echoAndLog "${FUNCNAME}(): Detecting network parameters."
	DEVICE=( $(ip -o link show up | awk '!/loopback/ {sub(/:.*/,"",$2); print $2}') )
	if [ -z "$DEVICE" ]; then
		errorAndLog "${FUNCNAME}(): Network devices not detected."
		exit 1
	fi
	for dev in ${DEVICE[*]}; do
		SERVERIP[i]=$(ip -o addr show dev "$dev" | awk '$3~/inet$/ {sub (/\/.*/, ""); print ($4)}')
		if [ -n "${SERVERIP[i]}" ]; then
			NETMASK[i]=$( cidr2mask $(ip -o addr show dev "$dev" | awk '$3~/inet$/ {sub (/.*\//, "", $4); print ($4)}') )
			NETBROAD[i]=$(ip -o addr show dev "$dev" | awk '$3~/inet$/ {print ($6)}')
			NETIP[i]=$(ip route list proto kernel | awk -v d="$dev" '$3==d && /src/ {sub (/\/.*/,""); print $1}')
			ROUTERIP[i]=$(ip route list default | awk -v d="$dev" '$5==d {print $3}')
			DEFAULTDEV=${DEFAULTDEV:-"$dev"}
		fi
		let i++
	done
	DNSIP=$(awk '/nameserver/ {print $2}' /etc/resolv.conf | head -n1)
	if [ -z "${NETIP[*]}" -o -z "${NETMASK[*]}" ]; then
		errorAndLog "${FUNCNAME}(): Network not detected."
		exit 1
	fi

	# Variables de ejecución de Apache
	# - APACHE_RUN_USER
	# - APACHE_RUN_GROUP
	if [ -f $APACHECFGDIR/envvars ]; then
		source $APACHECFGDIR/envvars
	fi
	APACHE_RUN_USER=${APACHE_RUN_USER:-"$APACHEUSER"}
	APACHE_RUN_GROUP=${APACHE_RUN_GROUP:-"$APACHEGROUP"}

	echoAndLog "${FUNCNAME}(): Default network device: $DEFAULTDEV."
}


############################################################
### Esqueleto para el Servicio pxe y contenedor tftpboot ###
############################################################

function tftpConfigure()
{
	echoAndLog "${FUNCNAME}(): Configuring TFTP service."
	# Habilitar TFTP y reiniciar Inetd.
	if [ -n "$TFTPSERV" ]; then
		if [ -f $INETDCFGDIR/$TFTPSERV ]; then
			perl -pi -e 's/disable.*/disable = no/' $INETDCFGDIR/$TFTPSERV
		else
			service=$TFTPSERV
			$ENABLESERVICE; $STARTSERVICE
		fi
	fi
	service=$INETDSERV
	$ENABLESERVICE; $STARTSERVICE

	# comprobamos el servicio tftp
	sleep 1
	testPxe
}

# Comprueba que haya conexión al servicio TFTP/PXE.
function testPxe ()
{
	echoAndLog "${FUNCNAME}(): Checking TFTP service... please wait."
	echo "test" >$TFTPCFGDIR/testpxe
	tftp -v 127.0.0.1 -c get testpxe /tmp/testpxe && echoAndLog "TFTP service is OK." || errorAndLog "TFTP service is down."
	rm -f $TFTPCFGDIR/testpxe /tmp/testpxe
}


########################################################################
## Configuración servicio Samba
########################################################################

# Configurar servicios Samba.
function smbConfigure()
{
	echoAndLog "${FUNCNAME}(): Configuring Samba service."

	backupFile $SAMBACFGDIR/smb.conf
	
	# Copiar plantailla de recursos para OpenGnsys
        sed -e "s/OPENGNSYSDIR/${INSTALL_TARGET//\//\\/}/g" \
		$WORKDIR/opengnsys/server/etc/smb-og.conf.tmpl > $SAMBACFGDIR/smb-og.conf
	# Configurar y recargar Samba"
	perl -pi -e "s/WORKGROUP/OPENGNSYS/; s/server string \=.*/server string \= OpenGnsys Samba Server/" $SAMBACFGDIR/smb.conf
	if ! grep -q "smb-og" $SAMBACFGDIR/smb.conf; then
		echo "include = $SAMBACFGDIR/smb-og.conf" >> $SAMBACFGDIR/smb.conf
	fi
	service=$SAMBASERV
	$ENABLESERVICE; $STARTSERVICE
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while configure Samba"
		return 1
	fi
	# Crear clave para usuario de acceso a los recursos.
	echo -ne "$OPENGNSYS_CLIENT_PASSWD\n$OPENGNSYS_CLIENT_PASSWD\n" | smbpasswd -a -s $OPENGNSYS_CLIENT_USER

	echoAndLog "${FUNCNAME}(): Added Samba configuration."
	return 0
}


########################################################################
## Configuración servicio Rsync
########################################################################

# Configurar servicio Rsync.
function rsyncConfigure()
{
	echoAndLog "${FUNCNAME}(): Configuring Rsync service."

	backupFile $RSYNCCFGDIR/rsyncd.conf

	# Configurar acceso a Rsync.
	sed -e "s/CLIENTUSER/$OPENGNSYS_CLIENT_USER/g" \
		$WORKDIR/opengnsys/repoman/etc/rsyncd.conf.tmpl > $RSYNCCFGDIR/rsyncd.conf
	sed -e "s/CLIENTUSER/$OPENGNSYS_CLIENT_USER/g" \
	    -e "s/CLIENTPASSWORD/$OPENGNSYS_CLIENT_PASSWD/g" \
		$WORKDIR/opengnsys/repoman/etc/rsyncd.secrets.tmpl > $RSYNCCFGDIR/rsyncd.secrets
	chown root.root $RSYNCCFGDIR/rsyncd.secrets
	chmod 600 $RSYNCCFGDIR/rsyncd.secrets

	# Habilitar Rsync y reiniciar Inetd.
	if [ -n "$RSYNCSERV" ]; then
		if [ -f /etc/default/rsync ]; then
			perl -pi -e 's/RSYNC_ENABLE=.*/RSYNC_ENABLE=inetd/' /etc/default/rsync
		fi
		if [ -f $INETDCFGDIR/rsync ]; then
			perl -pi -e 's/disable.*/disable = no/' $INETDCFGDIR/rsync
		else
			cat << EOT > $INETDCFGDIR/rsync
service rsync
{
	disable = no
	socket_type = stream
	wait = no
	user = root
	server = $(which rsync)
	server_args = --daemon
	log_on_failure += USERID
	flags = IPv6
}
EOT
		fi
		service=$RSYNCSERV $ENABLESERVICE
		service=$INETDSERV $STARTSERVICE
	fi

	echoAndLog "${FUNCNAME}(): Added Rsync configuration."
	return 0
}

	
########################################################################
## Configuración servicio DHCP
########################################################################

# Configurar servicios DHCP.
function dhcpConfigure()
{
	echoAndLog "${FUNCNAME}(): Sample DHCP configuration."

	local errcode=0
	local i=0
	local dev=""

	backupFile $DHCPCFGDIR/dhcpd.conf
	for dev in ${DEVICE[*]}; do
		if [ -n "${SERVERIP[i]}" ]; then
			backupFile $DHCPCFGDIR/dhcpd-$dev.conf
			sed -e "s/SERVERIP/${SERVERIP[i]}/g" \
			    -e "s/NETIP/${NETIP[i]}/g" \
			    -e "s/NETMASK/${NETMASK[i]}/g" \
			    -e "s/NETBROAD/${NETBROAD[i]}/g" \
			    -e "s/ROUTERIP/${ROUTERIP[i]}/g" \
			    -e "s/DNSIP/$DNSIP/g" \
			    $WORKDIR/opengnsys/server/etc/dhcpd.conf.tmpl > $DHCPCFGDIR/dhcpd-$dev.conf || errcode=1
		fi
		let i++
	done
	if [ $errcode -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while configuring DHCP server"
		return 1
	fi
	ln -f $DHCPCFGDIR/dhcpd-$DEFAULTDEV.conf $DHCPCFGDIR/dhcpd.conf
	service=$DHCPSERV
	$ENABLESERVICE; $STARTSERVICE
	echoAndLog "${FUNCNAME}(): Sample DHCP configured in \"$DHCPCFGDIR\"."
	return 0
}


#####################################################################
####### Funciones específicas de la instalación de Opengnsys
#####################################################################

# Instalar OpenGnsys Web Console.
function installWebFiles()
{
local $tmpdir jsonfile=$INSTALL_TARGET/etc/opengnsys.json

echoAndLog "${FUNCNAME}(): Copying backend files..."
sed -e "s/ database_name:.*/ database_name:     $OPENGNSYS_DATABASE/" \
    -e "s/ database_user:.*/ database_user:     $OPENGNSYS_DB_USER/" \
    -e "s/ database_password:.*/ database_password: $OPENGNSYS_DB_PASSWD/" \
       $WORKDIR/opengnsys/admin/WebConsole3/backend/app/config/parameters.yml.dist \
       > $WORKDIR/opengnsys/admin/WebConsole3/backend/app/config/parameters.yml
chown -R $OPENGNSYS_CLIENT_USER:$OPENGNSYS_CLIENT_USER $WORKDIR/opengnsys/admin/WebConsole3
cp -a $WORKDIR/opengnsys/admin/WebConsole3/backend $INSTALL_TARGET/www3
if [ $? != 0 ]; then
	errorAndLog "${FUNCNAME}(): Error copying backend files."
	exit 1
fi

echoAndLog "${FUNCNAME}(): Installing backend framework..."
pushd $INSTALL_TARGET/www3/backend
sudo -u $OPENGNSYS_CLIENT_USER composer.phar install
chmod 777 -R var/cache var/logs
sudo -u $OPENGNSYS_CLIENT_USER php bin/console doctrine:database:create --if-not-exists
sudo -u $OPENGNSYS_CLIENT_USER php bin/console doctrine:schema:update --force
echo yes | php bin/console doctrine:fixtures:load
php bin/console fos:user:create "$OPENGNSYS_DB_USER" "${OPENGNSYS_DB_USER}@localhost.localdomain" "$OPENGNSYS_DB_USER"
# Guardar tokens de seguridad.
read -e APIID APISECRET <<< \
	"$(php bin/console doctrine:query:sql "SELECT random_id, secret FROM og_core__clients WHERE id=1;" | \
	   awk -F\" '$2~/^(random_id|secret)$/ {getline; printf("%s ", $2)}')"
read -e CLIENTID CLIENTSECRET <<< \
	"$(php bin/console opengnsys:oauth-server:client:create --no-ansi \
			--grant-type="password" --grant-type="refresh_token" \
			--grant-type="token" \
			--grant-type="http://opengnsys.es/grants/og_client" | \
	   awk 'BEGIN {RS=" "}
		/^(id|secret)$/ {getline; gsub(/,/, ""); printf("%s ", $0)}')"
[ -f $jsonfile ] || echo "{}" > $jsonfile
jq '.client |= (. + {"id":"'"$CLIENTID"'", "secret":"'"$CLIENTSECRET"'"})' $jsonfile | sponge $jsonfile
chown root $jsonfile
chmod 600 $jsonfile
popd

echoAndLog "${FUNCNAME}(): Installing frontend framework..."
pushd $WORKDIR/opengnsys/admin/WebConsole3/frontend
tmpdir=$(sudo -u $OPENGNSYS_CLIENT_USER mktemp -d)
echo "cache = $tmpdir" > .npmrc
sudo -u $OPENGNSYS_CLIENT_USER npm install
sed -i -e "s/SERVERIP/$SERVERIP/" \
       -e "s/CLIENTID/1_$APIID/" \
       -e "s/CLIENTSECRET/$APISECRET/" src/environments/environment.ts
sed -i 's,base href=.*,base href="/opengnsys3/frontend/">,' src/index.html
sudo -u $OPENGNSYS_CLIENT_USER ng build
rm -fr $tmpdir

echoAndLog "${FUNCNAME}(): Copying frontend files..."
cp -a dist/opengnsysAngular6 $INSTALL_TARGET/www3/frontend
if [ $? != 0 ]; then
	errorAndLog "${FUNCNAME}(): Error copying frontend files."
	exit 1
fi
popd

echoAndLog "${FUNCNAME}(): Web files installed successfully."
}

# Copiar ficheros en la zona de descargas de OpenGnsys Web Console.
function installDownloadableFiles()
{
	INSTVERSION=1.1.0	###  Temporal.
	local FILENAME=ogagentpkgs-$INSTVERSION.tar.gz
	local TARGETFILE=$WORKDIR/$FILENAME
 
	# Descargar archivo comprimido, si es necesario.
	if [ -s $PROGRAMDIR/$FILENAME ]; then
		echoAndLog "${FUNCNAME}(): Moving $PROGRAMDIR/$FILENAME file to $(dirname $TARGETFILE)"
		mv $PROGRAMDIR/$FILENAME $TARGETFILE
	else
		echoAndLog "${FUNCNAME}(): Downloading $FILENAME"
		curl $DOWNLOADURL/$FILENAME -o $TARGETFILE
	fi
	if [ ! -s $TARGETFILE ]; then
		errorAndLog "${FUNCNAME}(): Cannot download $FILENAME"
		return 1
	fi
	
	# Descomprimir fichero en zona de descargas.
	tar xvzf $TARGETFILE -C $INSTALL_TARGET/www/descargas
	if [ $? != 0 ]; then
		errorAndLog "${FUNCNAME}(): Error uncompressing archive."
		exit 1
	fi
}

# Configuración específica de Apache.
function installWebConsoleApacheConf()
{
	if [ $# -ne 2 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local path_opengnsys_base="$1"
	local path_apache2_confd="$2"
	local CONSOLEDIR=${path_opengnsys_base}/www
	local sockfile

	if [ ! -d $path_apache2_confd ]; then
		errorAndLog "${FUNCNAME}(): path to apache2 conf.d can not found, verify your server installation"
		return 1
	fi

        mkdir -p $path_apache2_confd/{sites-available,sites-enabled}

	echoAndLog "${FUNCNAME}(): creating apache2 config file.."

	# Avtivar PHP-FPM.
	echoAndLog "${FUNCNAME}(): configuring PHP-FPM"
	service=$PHPFPMSERV
	$ENABLESERVICE; $STARTSERVICE
	sockfile=$(find /run/php -name "php*.sock" -type s -print 2>/dev/null | tail -1)

	# Activar módulos de Apache.
	$APACHEENABLEMODS
	# Activar HTTPS.
	$APACHEENABLESSL
	$APACHEMAKECERT
	# Genera configuración de consola web a partir del fichero plantilla.
	if [ -n "$(apachectl -v | grep "2\.[0-2]")" ]; then
		# Configuración para versiones anteriores de Apache.
		sed -e "s,CONSOLEDIR,$CONSOLEDIR,g" \
			$WORKDIR/opengnsys/server/etc/apache-prev2.4.conf.tmpl > $path_apache2_confd/$APACHESITESDIR/${APACHEOGSITE}
	else
		# Configuración específica a partir de Apache 2.4
		if [ -n "$sockfile" ]; then
			sed -e "s,CONSOLEDIR,$CONSOLEDIR,g" \
			    -e "s,proxy:fcgi:.*,proxy:unix:${sockfile%% *}|fcgi://localhost\",g" \
				$WORKDIR/opengnsys/server/etc/apache.conf.tmpl > $path_apache2_confd/$APACHESITESDIR/${APACHEOGSITE}.conf
		else
			sed -e "s,CONSOLEDIR,$CONSOLEDIR,g" \
				$WORKDIR/opengnsys/server/etc/apache.conf.tmpl > $path_apache2_confd/$APACHESITESDIR/${APACHEOGSITE}.conf
		fi
	fi
	$APACHEENABLEOG
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): config file can't be linked to apache conf, verify your server installation"
		return 1
	fi
	echoAndLog "${FUNCNAME}(): config file created and linked, restarting apache daemon"
	service=$APACHESERV
	$ENABLESERVICE; $STARTSERVICE
	return 0
}


# Crear documentación Doxygen para la consola web.
function makeDoxygenFiles()
{
	echoAndLog "${FUNCNAME}(): Making Doxygen web files..."
	$WORKDIR/opengnsys/installer/ogGenerateDoc.sh \
			$WORKDIR/opengnsys/client/engine $INSTALL_TARGET/www
	if [ ! -d "$INSTALL_TARGET/www/html" ]; then
		errorAndLog "${FUNCNAME}(): unable to create Doxygen web files."
		return 1
	fi
	mv "$INSTALL_TARGET/www/html" "$INSTALL_TARGET/www/api"
	echoAndLog "${FUNCNAME}(): Doxygen web files created successfully."
}


# Crea la estructura base de la instalación de opengnsys
function createDirs()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local path_opengnsys_base="$1"

	# Crear estructura de directorios.
	echoAndLog "${FUNCNAME}(): creating directory paths in $path_opengnsys_base"
	mkdir -p $path_opengnsys_base
	mkdir -p $path_opengnsys_base/bin
	mkdir -p $path_opengnsys_base/client/{cache,images,log}
	mkdir -p $path_opengnsys_base/doc
	mkdir -p $path_opengnsys_base/etc
	mkdir -p $path_opengnsys_base/lib
	mkdir -p $path_opengnsys_base/log/clients
	ln -fs $path_opengnsys_base/log /var/log/opengnsys
	mkdir -p $path_opengnsys_base/sbin
	mkdir -p $path_opengnsys_base/www/descargas
	mkdir -p $path_opengnsys_base/www3		### TEMPORAL
	mkdir -p $path_opengnsys_base/images/groups
	mkdir -p $TFTPCFGDIR
	ln -fs $TFTPCFGDIR $path_opengnsys_base/tftpboot
	mkdir -p $path_opengnsys_base/tftpboot/{menu.lst,grub}
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while creating dirs. Do you have write permissions?"
		return 1
	fi

	# Crear usuario ficticio.
	if id -u $OPENGNSYS_CLIENT_USER &>/dev/null; then 
		echoAndLog "${FUNCNAME}(): user \"$OPENGNSYS_CLIENT_USER\" is already created"
	else
		echoAndLog "${FUNCNAME}(): creating OpenGnsys user"
		useradd $OPENGNSYS_CLIENT_USER 2>/dev/null
		if [ $? -ne 0 ]; then
			errorAndLog "${FUNCNAME}(): error creating OpenGnsys user"
			return 1
		fi
	fi

	# Mover el fichero de registro de instalación al directorio de logs.
	echoAndLog "${FUNCNAME}(): moving installation log file"
	mv $LOG_FILE $OGLOGFILE && LOG_FILE=$OGLOGFILE
	chmod 600 $LOG_FILE

	echoAndLog "${FUNCNAME}(): directory paths created"
	return 0
}

# Copia ficheros de configuración y ejecutables genéricos del servidor.
function copyServerFiles ()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local path_opengnsys_base="$1"

	# Lista de ficheros y directorios origen y de directorios destino.
	local SOURCES=( server/tftpboot \
			/usr/lib/shim/shimx64.efi.signed \
			/usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed \
			server/bin \
			repoman/bin \
			server/lib \
			admin/Sources/Services/ogAdmServerAux
			admin/Sources/Services/ogAdmRepoAux
			installer/opengnsys_uninstall.sh \
			installer/opengnsys_update.sh \
			installer/opengnsys_update3.sh \
			installer/opengnsys_export.sh \
			installer/opengnsys_import.sh \
			doc )
	local TARGETS=( tftpboot \
			tftpboot \
			tftpboot/grubx64.efi \
			bin \
			bin \
			lib \
			sbin \
			sbin \
			lib \
			lib \
			lib \
			lib \
			lib \
			doc )

	if [ ${#SOURCES[@]} != ${#TARGETS[@]} ]; then
		errorAndLog "${FUNCNAME}(): inconsistent number of array items"
		exit 1
	fi

	# Copiar ficheros.
	echoAndLog "${FUNCNAME}(): copying files to server directories"

	pushd $WORKDIR/opengnsys
	local i
	for (( i = 0; i < ${#SOURCES[@]}; i++ )); do
		if [ -f "${SOURCES[$i]}" ]; then
			echoAndLog "Copying ${SOURCES[$i]} to $path_opengnsys_base/${TARGETS[$i]}"
			cp -a "${SOURCES[$i]}" "${path_opengnsys_base}/${TARGETS[$i]}"
		elif [ -d "${SOURCES[$i]}" ]; then
			echoAndLog "Copying content of ${SOURCES[$i]} to $path_opengnsys_base/${TARGETS[$i]}"
			cp -a "${SOURCES[$i]}"/* "${path_opengnsys_base}/${TARGETS[$i]}"
		else
			warningAndLog "Unable to copy ${SOURCES[$i]} to $path_opengnsys_base/${TARGETS[$i]}"
		fi
	done

	popd
}


####################################################################
### Funciones de copia de la Interface de administración
####################################################################

# Copiar carpeta de Interface
function copyInterfaceAdm ()
{
	local hayErrores=0
	
	# Crear carpeta y copiar Interface
	echoAndLog "${FUNCNAME}(): Copying Administration Interface Folder"
	cp -ar $WORKDIR/opengnsys/admin/Interface $INSTALL_TARGET/client/interfaceAdm
	if [ $? -ne 0 ]; then
		echoAndLog "${FUNCNAME}(): error while copying Administration Interface Folder"
		hayErrores=1
	fi
	chown $OPENGNSYS_CLIENT_USER:$OPENGNSYS_CLIENT_USER $INSTALL_TARGET/client/interfaceAdm/CambiarAcceso
	chmod 700 $INSTALL_TARGET/client/interfaceAdm/CambiarAcceso

	return $hayErrores
}

####################################################################
### Funciones instalacion cliente opengnsys
####################################################################

function copyClientFiles()
{
	local errstatus=0

	echoAndLog "${FUNCNAME}(): Copying OpenGnsys Client files."
	cp -a $WORKDIR/opengnsys/client/shared/* $INSTALL_TARGET/client
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while copying client estructure"
		errstatus=1
	fi
	
	echoAndLog "${FUNCNAME}(): Copying OpenGnsys Cloning Engine files."
	mkdir -p $INSTALL_TARGET/client/lib/engine/bin
	cp -a $WORKDIR/opengnsys/client/engine/*.lib* $INSTALL_TARGET/client/lib/engine/bin
	if [ $? -ne 0 ]; then
		errorAndLog "${FUNCNAME}(): error while copying engine files"
		errstatus=1
	fi
	
	if [ $errstatus -eq 0 ]; then
		echoAndLog "${FUNCNAME}(): client copy files success."
	else
		errorAndLog "${FUNCNAME}(): client copy files with errors"
	fi

	return $errstatus
}


# Crear cliente OpenGnsys.
function clientCreate()
{
	if [ $# -ne 1 ]; then
		errorAndLog "${FUNCNAME}(): invalid number of parameters"
		exit 1
	fi

	local FILENAME="$1"
	local TARGETFILE=$INSTALL_TARGET/lib/$FILENAME
 
	# Descargar cliente, si es necesario.
	if [ -s $PROGRAMDIR/$FILENAME ]; then
		echoAndLog "${FUNCNAME}(): Moving $PROGRAMDIR/$FILENAME file to $(dirname $TARGETFILE)"
		mv $PROGRAMDIR/$FILENAME $TARGETFILE
	else
		echoAndLog "${FUNCNAME}(): Downloading $FILENAME"
		oglivecli download $FILENAME
	fi
	if [ ! -s $TARGETFILE ]; then
		errorAndLog "${FUNCNAME}(): Error loading $FILENAME"
		return 1
	fi

	# Montar imagen, copiar cliente ogclient y desmontar.
	echoAndLog "${FUNCNAME}(): Installing ogLive Client"
	echo -ne "$OPENGNSYS_CLIENT_PASSWD\n$OPENGNSYS_CLIENT_PASSWD\n" | \
			oglivecli install $FILENAME
	# Adaptar permisos.
	chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP $INSTALL_TARGET/tftpboot/menu.lst

	echoAndLog "${FUNCNAME}(): Client generation success"
}


# Función temporal para generar y copiar el agente OGAgent para ogLive
function createOgagentPackage () 
{
local ogagentdir=$WORKDIR/opengnsys/admin/Sources/Clients/ogagent/oglive

echoAndLog "${FUNCNAME}(): Creating OGAgent for ogLive package..."
OGAGENTFILE=$($ogagentdir/build-package.sh | awk -F\' '/building package/ {print $(NF-1)}')
if [ -z "$OGAGENTFILE" ]; then
	errorAndLog "${FUNCNAME}(): Error generating OGAgent pacakage."
	return 1
fi
OGAGENTFILE=$(realpath $ogagentdir/$OGAGENTFILE)
cp -va $OGAGENTFILE $INSTALL_TARGET/images
echoAndLog "${FUNCNAME}(): OGAgent for ogLive package has been copied to the repository"
}


# Configuración básica de servicios de OpenGnsys
function openGnsysConfigure()
{
	local i=0
	local dev=""
	local CONSOLEURL

	echoAndLog "${FUNCNAME}(): Copying init files."
	cp -a $WORKDIR/opengnsys/admin/Sources/Services/opengnsys.init /etc/init.d/opengnsys
	cp -a $WORKDIR/opengnsys/admin/Sources/Services/opengnsys.default /etc/default/opengnsys
	# Deshabilitar servicios de BitTorrent si no están instalados.
	if [ ! -e /usr/bin/bttrack ]; then
		sed -i 's/RUN_BTTRACKER="yes"/RUN_BTTRACKER="no"/; s/RUN_BTSEEDER="yes"/RUN_BTSEEDER="no"/' \
			/etc/default/opengnsys
	fi
	echoAndLog "${FUNCNAME}(): Creating cron files."
	echo "* * * * *   root   [ -x $INSTALL_TARGET/bin/opengnsys.cron ] && $INSTALL_TARGET/bin/opengnsys.cron" > /etc/cron.d/opengnsys
	echo "* * * * *   root   [ -x $INSTALL_TARGET/bin/torrent-creator ] && $INSTALL_TARGET/bin/torrent-creator" > /etc/cron.d/torrentcreator
	echo "5 * * * *   root   [ -x $INSTALL_TARGET/bin/torrent-tracker ] && $INSTALL_TARGET/bin/torrent-tracker" > /etc/cron.d/torrenttracker
	echo "* * * * *   root   [ -x $INSTALL_TARGET/bin/deletepreimage ] && $INSTALL_TARGET/bin/deletepreimage" > /etc/cron.d/imagedelete
	echo "* * * * *   root   [ -x $INSTALL_TARGET/bin/ogagentqueue.cron ] && $INSTALL_TARGET/bin/ogagentqueue.cron" > /etc/cron.d/ogagentqueue

	echoAndLog "${FUNCNAME}(): Creating logrotate configuration files."
	sed -e "s/OPENGNSYSDIR/${INSTALL_TARGET//\//\\/}/g" \
		$WORKDIR/opengnsys/server/etc/logrotate.tmpl > /etc/logrotate.d/opengnsysServer

	sed -e "s/OPENGNSYSDIR/${INSTALL_TARGET//\//\\/}/g" \
		$WORKDIR/opengnsys/repoman/etc/logrotate.tmpl > /etc/logrotate.d/opengnsysRepo

	echoAndLog "${FUNCNAME}(): Creating OpenGnsys config files."
	for dev in ${DEVICE[*]}; do
		if [ -n "${SERVERIP[i]}" ]; then
			sed -e "s/SERVERIP/${SERVERIP[i]}/g" \
			    -e "s/REPOKEY/$OPENGNSYS_REPOKEY/g" \
				$WORKDIR/opengnsys/repoman/etc/ogAdmRepo.cfg.tmpl > $INSTALL_TARGET/etc/ogAdmRepo-$dev.cfg
			if [ "$dev" == "$DEFAULTDEV" ]; then
				OPENGNSYS_CONSOLEURL="$CONSOLEURL"
			fi
		fi
		let i++
	done
	ln -f $INSTALL_TARGET/etc/ogAdmRepo-$DEFAULTDEV.cfg $INSTALL_TARGET/etc/ogAdmRepo.cfg

	# Configuración del motor de clonación.
	# - Zona horaria del servidor.
	TZ=$(timedatectl status|awk -F"[:()]" '/Time.*zone/ {print $2}')
	cat << EOT >> $INSTALL_TARGET/client/etc/engine.cfg
# OpenGnsys Server timezone.
TZ="${TZ// /}"
EOT

	# Revisar permisos generales.
	if [ -x $INSTALL_TARGET/bin/checkperms ]; then
		echoAndLog "${FUNCNAME}(): Checking permissions."
		OPENGNSYS_DIR="$INSTALL_TARGET" OPENGNSYS_USER="$OPENGNSYS_CLIENT_USER" APACHE_USER="$APACHE_RUN_USER" APACHE_GROUP="$APACHE_RUN_GROUP" checkperms
	fi

	# Evitar inicio de duplicado en Ubuntu 14.04 (Upstart y SysV Init).
	if [ -f /etc/init/${MYSQLSERV}.conf -a -n "$(which initctl 2>/dev/null)" ]; then
		service=$MYSQLSERV
		$DISABLESERVICE
	fi
}


#####################################################################
#######  Función de resumen informativo de la instalación
#####################################################################

function installationSummary()
{
	local VERSIONFILE REVISION

	# Crear fichero de versión y revisión, si no existe.
	VERSIONFILE="$INSTALL_TARGET/doc/VERSION.json"
	[ -f $VERSIONFILE ] || echo '{ "project": "OpenGnsys" }' >$VERSIONFILE
	# Incluir datos de revisión, si se está instalando desde el repositorio
	# de código o si no está incluida en el fichero de versión.
	if [ $REMOTE -eq 1 ] || [ -z "$(jq -r '.release' $VERSIONFILE)" ]; then
		# Revisión: rAñoMesDía.Gitcommit (8 caracteres de fecha y 7 primeros de commit).
		REVISION=$(curl -s "$API_URL" | jq '"r" + (.commit.commit.committer.date | split("-") | join("")[:8]) + "." + (.commit.sha[:7])')
		jq ".release=$REVISION" $VERSIONFILE | sponge $VERSIONFILE
	fi
	VERSION="$(jq -r '[.project, .version, .codename, .release] | join(" ")' $VERSIONFILE 2>/dev/null)"

	# Mostrar información.
	echo
	echoAndLog "OpenGnsys Installation Summary"
	echo       "=============================="
	echoAndLog "Project version:                  $VERSION"
	echoAndLog "Installation directory:           $INSTALL_TARGET"
	echoAndLog "Installation log file:            $LOG_FILE"
	echoAndLog "Repository directory:             $INSTALL_TARGET/images"
	echoAndLog "DHCP configuration directory:     $DHCPCFGDIR"
	echoAndLog "TFTP configuration directory:     $TFTPCFGDIR"
	echoAndLog "Installed ogLive client(s):       $(oglivecli list | awk '{print $2}')"
	echoAndLog "Samba configuration directory:    $SAMBACFGDIR"
	echoAndLog "Web Console URL:                  $OPENGNSYS_CONSOLEURL"
	echoAndLog "Web Console access data:          entered by the user"
	if grep -q "^RUN_BTTRACK.*no" /etc/default/opengnsys; then
		echoAndLog "BitTorrent service is disabled."
	fi
	echo
	echoAndLog "Post-Installation Instructions:"
	echo       "==============================="
	echoAndLog "You can improve server security by configuring firewall and SELinux,"
	echoAndLog "   running \"$INSTALL_TARGET/lib/security-config\" script as root."
	echoAndLog "It's strongly recommended to synchronize this server with an NTP server."
	echoAndLog "Review or edit all configuration files."
	echoAndLog "Insert DHCP configuration data and restart service."
	echoAndLog "Optional: Log-in as Web Console admin user."
	echoAndLog " - Review default Organization data and assign access to users."
	echoAndLog "Log-in as Web Console organization user."
	echoAndLog " - Insert OpenGnsys data (labs, computers, menus, etc)."
echo
}



#####################################################################
####### Proceso de instalación de OpenGnsys
#####################################################################

echoAndLog "OpenGnsys installation begins at $(date)"
pushd $WORKDIR

# Detectar datos iniciales de auto-configuración del instalador.
autoConfigure

# Detectar parámetros de red y comprobar si hay conexión.
getNetworkSettings
if [ $? -ne 0 ]; then
	errorAndLog "Error reading default network settings."
	exit 1
fi
checkNetworkConnection
if [ $? -ne 0 ]; then
	errorAndLog "Error connecting to server. Causes:"
	errorAndLog " - Network is unreachable, review devices parameters."
	errorAndLog " - You are inside a private network, configure the proxy service."
	errorAndLog " - Server is temporally down, try agian later."
	exit 1
fi

# Detener servicios de OpenGnsys, si están activos previamente.
[ -f /etc/init.d/opengnsys ] && /etc/init.d/opengnsys stop

# Actualizar repositorios
updatePackageList

# Instalación de dependencias (paquetes de sistema operativo).
declare -a notinstalled
checkDependencies DEPENDENCIES notinstalled
if [ $? -ne 0 ]; then
	installDependencies notinstalled
	if [ $? -ne 0 ]; then
		echoAndLog "Error while installing some dependeces, please verify your server installation before continue"
		exit 1
	fi
fi
if [ -n "$INSTALLEXTRADEPS" ]; then
	echoAndLog "Installing extra dependencies"
	for (( i=0; i<${#INSTALLEXTRADEPS[*]}; i++ )); do
		eval ${INSTALLEXTRADEPS[i]}
	done
fi	

# Detectar datos de auto-configuración después de instalar paquetes.
autoConfigurePost

# Arbol de directorios de OpenGnsys.
createDirs ${INSTALL_TARGET}
if [ $? -ne 0 ]; then
	errorAndLog "Error while creating directory paths!"
	exit 1
fi

# Si es necesario, descarga el repositorio de código en directorio temporal
if [ $REMOTE -eq 1 ]; then
	downloadCode $CODE_URL
	if [ $? -ne 0 ]; then
		errorAndLog "Error while getting code from the repository"
		exit 1
	fi
else
	ln -fs "$(dirname $PROGRAMDIR)" opengnsys
fi

# Copiar carpeta Interface entre administración y motor de clonación.
copyInterfaceAdm
if [ $? -ne 0 ]; then
	errorAndLog "Error while copying Administration Interface"
	exit 1
fi

# Configuración de TFTP.
tftpConfigure

# Configuración de Samba.
smbConfigure
if [ $? -ne 0 ]; then
	errorAndLog "Error while configuring Samba server!"
	exit 1
fi

# Configuración de Rsync.
rsyncConfigure

# Configuración ejemplo DHCP.
dhcpConfigure
if [ $? -ne 0 ]; then
	errorAndLog "Error while copying your dhcp server files!"
	exit 1
fi

# Copiar ficheros de servicios OpenGnsys Server.
copyServerFiles ${INSTALL_TARGET}
if [ $? -ne 0 ]; then
	errorAndLog "Error while copying the server files!"
	exit 1
fi
INSTVERSION=$(jq -r '.version' $INSTALL_TARGET/doc/VERSION.json)

# Instalar base de datos de OpenGnsys Admin.
isInArray notinstalled "mysql-server" || isInArray notinstalled "mariadb-server"
if [ $? -eq 0 ]; then
	# Habilitar gestor de base de datos (MySQL, si falla, MariaDB).
	service=$MYSQLSERV
	$ENABLESERVICE
	if [ $? != 0 ]; then
		service=$MARIADBSERV
		$ENABLESERVICE
	fi
	# Activar gestor de base de datos.
	$STARTSERVICE
	# Asignar clave del usuario "root".
	mysqlSetRootPassword "${MYSQL_ROOT_PASSWORD}"
else
	# Si ya está instalado el gestor de bases de datos, obtener clave de "root", 
	mysqlGetRootPassword
fi

mysqlTestConnection "${MYSQL_ROOT_PASSWORD}"
if [ $? -ne 0 ]; then
	errorAndLog "Error while connection to mysql"
	exit 1
fi
mysqlDbExists ${OPENGNSYS_DATABASE}
if [ $? -ne 0 ]; then
	echoAndLog "Creating Web Console database"
	mysqlCreateDb ${OPENGNSYS_DATABASE}
	if [ $? -ne 0 ]; then
		errorAndLog "Error while creating Web Console database"
		exit 1
	fi
else
	echoAndLog "Web Console database exists, ommiting creation"
fi

mysqlCheckUserExists ${OPENGNSYS_DB_USER}
if [ $? -ne 0 ]; then
	echoAndLog "Creating user in database"
	mysqlCreateAdminUserToDb ${OPENGNSYS_DATABASE} ${OPENGNSYS_DB_USER} "${OPENGNSYS_DB_PASSWD}"
	if [ $? -ne 0 ]; then
		errorAndLog "Error while creating database user"
		exit 1
	fi

fi
rm -f $TMPMYCNF

# Copiando páqinas web.
installWebFiles
# Descargar/descomprimir archivos descargables.
installDownloadableFiles
# Generar páqinas web de documentación de la API
makeDoxygenFiles

# Creando configuración de Apache.
installWebConsoleApacheConf $INSTALL_TARGET $APACHECFGDIR
if [ $? -ne 0 ]; then
	errorAndLog "Error configuring Apache for OpenGnsys Admin"
	exit 1
fi

popd

# Crear la estructura de los accesos al servidor desde el cliente (shared)
copyClientFiles
if [ $? -ne 0 ]; then
	errorAndLog "Error creating client structure"
fi

# Crear la estructura del cliente de OpenGnsys.
for i in $OGLIVE; do
	if ! clientCreate "$i"; then
		errorAndLog "Error creating client $i"
		exit 1
	fi
done

# Copiar paquete ogagent-oglive en el repositorio.
createOgagentPackage

# Configuración de servicios de OpenGnsys
openGnsysConfigure

# Mostrar sumario de la instalación e instrucciones de post-instalación.
installationSummary

#rm -rf $WORKDIR
echoAndLog "OpenGnsys installation finished at $(date)"
exit 0

