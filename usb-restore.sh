#!/bin/bash
PC_ID=$(blkid -o value -s UUID /dev/sde2 2>/dev/null | cut -c1-8)

if [[ -z "$PC_ID" ]]; then
	echo "[usb-restore] No se pudo identificar el PC - arrancando normal"
	exit 0
fi

SNAPSHOT=$(ls -dt /mnt/usb-persist/snapshots/${PC_ID}/*/ 2>/dev/null | head -1)

if [[ -z "$SNAPSHOT" ]]; then
	echo "[usb-restore] No hay snapshot para PC ${PC_ID} - arrancando normal"
	exit 0
fi

echo "[usb-restore] PC: ${PC_ID}"
echo "[usb-restore] Restaurando desde: $SNAPSHOT"
rsync -aAX --delete "SNAPSHOT" / \
	--exclude=/proc \
	--exclude=/sys \
	--exclude=/dev \
	--exclude=/run \
	--exclude=/tmp \
	--exclude=/mnt \
	--exclude=/lost+found
echo "[usb-restore] Restauración completa"
