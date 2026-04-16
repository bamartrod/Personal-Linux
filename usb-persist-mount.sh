#!/usr/bin/env bash
# Auto-generado por usb-persist-setup.sh
# NO EDITAR MANUALMENTE

PARTITION="/dev/sdf3"
MOUNT_POINT="/mnt/usb-persist"
PERSIST_BASE="/mnt/usb-persist/persist"
REAL_USER="root"
REAL_HOME="/root"

# Verificar que la partición existe
if [[ ! -b "$PARTITION" ]]; then
  echo "[usb-persist] Partición $PARTITION no encontrada — saltando"
  exit 0
fi

mkdir -p "$MOUNT_POINT"
mountpoint -q "$MOUNT_POINT" || mount "$PARTITION" "$MOUNT_POINT"

# Crear dirs si no existen (primer uso en este PC)
mkdir -p "${PERSIST_BASE}"/{tmp,var_tmp,cache/system,cache/browser,cache/thumbnails,downloads,logs,journal}
chmod 1777 "${PERSIST_BASE}/tmp" "${PERSIST_BASE}/var_tmp"
chown -R "${REAL_USER}:${REAL_USER}" "${PERSIST_BASE}/cache" "${PERSIST_BASE}/downloads"

# Bind mounts del sistema
mountpoint -q /tmp     || mount --bind "${PERSIST_BASE}/tmp"     /tmp
mountpoint -q /var/tmp || mount --bind "${PERSIST_BASE}/var_tmp" /var/tmp
mountpoint -q /var/log/journal || mount --bind "${PERSIST_BASE}/journal /var/log/journal"
mountpoint -q /var/log || mount --bind "${PERSIST_BASE}/logs /var/log"

# Bind mounts del usuario
mkdir -p "${REAL_HOME}/.cache"
mountpoint -q "${REAL_HOME}/.cache" ||   mount --bind "${PERSIST_BASE}/cache/system" "${REAL_HOME}/.cache"

mkdir -p "${REAL_HOME}/.cache/thumbnails"
mountpoint -q "${REAL_HOME}/.cache/thumbnails" ||   mount --bind "${PERSIST_BASE}/cache/thumbnails" "${REAL_HOME}/.cache/thumbnails"

# Symlink Downloads si no existe
[[ -L "${REAL_HOME}/Downloads" ]] ||   ln -sf "${PERSIST_BASE}/downloads" "${REAL_HOME}/Downloads"

chown -h "${REAL_USER}:${REAL_USER}" "${REAL_HOME}/Downloads"
echo "[usb-persist] Montajes aplicados correctamente"
