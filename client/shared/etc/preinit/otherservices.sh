#!/bin/bash
#/**
#@file    otherservices.sh
#@brief   Script de inicio para cargar otros servicios complementarios.
#@version 1.0.3
#@author  Ramon Gomez, ETSII Universidad de Sevilla
#@date    2012-01-12
#*/


# Lanzar servicios complementarios del cliente.
echo "${MSG_OTHERSERVICES:-.}"

# Iniciar rsyslog, si es necesario.
[ -S /dev/log ] || service rsyslog start

# Adpatar la clave de "root" para acceso SSH.
PASS=$(grep "^[ 	]*\(export \)\?OPTIONS=" /scripts/ogfunctions 2>&1 | \
	sed 's/\(.*\)pass=\(\w*\)\(.*\)/\2/')
PASS=${PASS:-"og"}
echo -ne "$PASS\n$PASS\n" | passwd root 2>/dev/null
# Cargar el entorno OpenGnsys en conexión SSH.
cp -a $OPENGNSYS/etc/preinit/loadenviron.sh /etc/profile.d/
# Arrancar SSH.
/etc/init.d/ssh start &>/dev/null

# Desactivado apagado de monitor.
#setterm -blank 0 -powersave off -powerdown 0 < /dev/console > /dev/console 2>&1

# Activado WOL en la interfaz usada en arranque PXE.
ethtool -s $DEVICE wol g 2>/dev/null

# TODO Localizar correctamente el script de arranque.
[ -f /opt/opengnsys/scripts/runhttplog.sh ] && /opt/opengnsys/scripts/runhttplog.sh 2>/dev/null
