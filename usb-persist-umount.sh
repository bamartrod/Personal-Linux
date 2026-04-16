#!/usr/bin/env bash
REAL_HOME="/root"
MOUNT_POINT="/mnt/usb-persist"

umount "${REAL_HOME}/.cache/thumbnails" 2>/dev/null || true
umount "${REAL_HOME}/.cache"            2>/dev/null || true
umount /var/tmp                          2>/dev/null || true
umount /tmp                              2>/dev/null || true
umount "${MOUNT_POINT}"                 2>/dev/null || true
echo "[usb-persist] Desmontaje limpio completado"
