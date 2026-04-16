#!/usr/bin/env bash
echo "Desinstalando USB-Persist..."
systemctl stop usb-persist 2>/dev/null || true
systemctl disable usb-persist 2>/dev/null || true
rm -f /etc/systemd/system/usb-persist.service
rm -f /usr/local/bin/usb-persist-mount.sh
rm -f /usr/local/bin/usb-persist-umount.sh
rm -f /usr/local/bin/usb-persist-remove.sh
systemctl daemon-reload
echo "Desinstalación completa. Reinicia para restaurar rutas originales."
