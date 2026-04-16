#!/usr/bin/env bash
# ============================================================
#  USB-PERSIST  —  Persistencia de archivos no esenciales
#  Autor: generado para Arch Linux USB portable
#  Uso:   sudo bash usb-persist-setup.sh [PARTICIÓN]
#         Ejemplo: sudo bash usb-persist-setup.sh sdf3
# ============================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'
B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'; N='\033[0m'

# ── Configuración fija (misma ruta en todos los PCs) ─────────
MOUNT_LABEL="usb-persist"
MOUNT_POINT="/mnt/${MOUNT_LABEL}"
PERSIST_BASE="${MOUNT_POINT}/persist"

# Subdirectorios dentro del HDD (ruta fija, portable)
declare -A DIRS=(
  [tmp]="${PERSIST_BASE}/tmp"
  [var_tmp]="${PERSIST_BASE}/var_tmp"
  [cache]="${PERSIST_BASE}/cache/system"
  [downloads]="${PERSIST_BASE}/downloads"
  [browser]="${PERSIST_BASE}/cache/browser"
  [thumbnails]="${PERSIST_BASE}/cache/thumbnails"
  [logs]="${PERSIST_BASE}/logs"
)

# ── Banner ───────────────────────────────────────────────────
banner() {
  echo -e "${C}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║         USB-PERSIST  ·  Arch Linux USB           ║"
  echo "  ║   Redirige temporales y caché al HDD del PC      ║"
  echo "  ╚══════════════════════════════════════════════════╝${N}"
  echo
}

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "  ${B}[·]${N} $*"; }
ok()      { echo -e "  ${G}[✓]${N} $*"; }
warn()    { echo -e "  ${Y}[!]${N} $*"; }
error()   { echo -e "  ${R}[✗]${N} $*"; exit 1; }
section() { echo -e "\n  ${W}━━━  $*  ━━━${N}"; }

# ── Validaciones iniciales ───────────────────────────────────
check_root() {
  [[ $EUID -eq 0 ]] || error "Ejecuta como root: sudo bash $0 [PARTICIÓN]"
}

get_partition() {
  if [[ -n "${1:-}" ]]; then
    PARTITION="/dev/$1"
  else
    echo -e "\n  ${Y}Uso: sudo bash $0 <partición>${N}"
    echo -e "  Ejemplo: sudo bash $0 sdf3\n"
    echo -e "  Particiones disponibles:"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -v loop | sed 's/^/    /'
    echo
    read -rp "  Ingresa la partición (ej: sdf3): " PART_INPUT
    PARTITION="/dev/${PART_INPUT}"
  fi

  [[ -b "$PARTITION" ]] || error "Partición no encontrada: ${PARTITION}"
  info "Partición seleccionada: ${C}${PARTITION}${N}"
}

detect_user() {
  # Usuario real (no root), para redirigir ~/.cache y ~/Downloads
  REAL_USER="${SUDO_USER:-$(who | awk 'NR==1{print $1}')}"
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  [[ -d "$REAL_HOME" ]] || error "No se pudo detectar el home del usuario"
  info "Usuario detectado: ${C}${REAL_USER}${N} → ${REAL_HOME}"
}

# ── 1. Montar el HDD ─────────────────────────────────────────
mount_hdd() {
  section "Montando HDD"

  mkdir -p "$MOUNT_POINT"

  if mountpoint -q "$MOUNT_POINT"; then
    warn "Ya montado en ${MOUNT_POINT}, continuando..."
  else
    # Detectar sistema de archivos
    FS_TYPE=$(blkid -o value -s TYPE "$PARTITION" 2>/dev/null || echo "ext4")
    info "Sistema de archivos detectado: ${FS_TYPE}"

    case "$FS_TYPE" in
      ext4|ext3|ext2|btrfs|xfs|f2fs)
        mount -t "$FS_TYPE" "$PARTITION" "$MOUNT_POINT"
        ;;
      ntfs|ntfs-3g)
        mount -t ntfs-3g -o uid="$(id -u "$REAL_USER")",gid="$(id -g "$REAL_USER")" \
              "$PARTITION" "$MOUNT_POINT"
        ;;
      vfat|fat32|exfat)
        mount -t "$FS_TYPE" -o uid="$(id -u "$REAL_USER")",gid="$(id -g "$REAL_USER")" \
              "$PARTITION" "$MOUNT_POINT"
        ;;
      *)
        mount "$PARTITION" "$MOUNT_POINT"
        ;;
    esac
    ok "HDD montado en ${MOUNT_POINT}"
  fi
}

# ── 2. Crear estructura fija en el HDD ───────────────────────
create_structure() {
  section "Creando estructura de directorios en HDD"

  for key in "${!DIRS[@]}"; do
    dir="${DIRS[$key]}"
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
      ok "Creado: ${dir}"
    else
      info "Ya existe: ${dir}"
    fi
  done

  # Permisos especiales para tmp
  chmod 1777 "${DIRS[tmp]}"
  chmod 1777 "${DIRS[var_tmp]}"

  # Propiedad correcta para directorios de usuario
  chown -R "${REAL_USER}:${REAL_USER}" \
    "${DIRS[cache]}" \
    "${DIRS[downloads]}" \
    "${DIRS[browser]}" \
    "${DIRS[thumbnails]}" \
    "${DIRS[logs]}"

  ok "Estructura lista en ${PERSIST_BASE}"
}

# ── 3. Bind mounts del sistema ───────────────────────────────
apply_bind_mounts() {
  section "Aplicando bind mounts del sistema"

  bind_mount() {
    local src="$1" dst="$2"
    if mountpoint -q "$dst"; then
      warn "Ya montado: ${dst}"
      return
    fi
    # Vaciar destino si tiene contenido antiguo residual
    mount --bind "$src" "$dst"
    ok "Bind mount: ${C}${dst}${N} → ${src}"
  }

  bind_mount "${DIRS[tmp]}"     /tmp
  bind_mount "${DIRS[var_tmp]}" /var/tmp
}

# ── 4. Redirigir directorios del usuario ─────────────────────
apply_user_redirects() {
  section "Redirigiendo directorios del usuario (${REAL_USER})"

  USER_CACHE="${REAL_HOME}/.cache"
  USER_DOWNLOADS="${REAL_HOME}/Downloads"
  USER_THUMBS="${REAL_HOME}/.cache/thumbnails"

  # ~/.cache via bind mount
  if ! mountpoint -q "$USER_CACHE"; then
    mkdir -p "$USER_CACHE"
    mount --bind "${DIRS[cache]}" "$USER_CACHE"
    ok "Caché de usuario: ${C}${USER_CACHE}${N} → ${DIRS[cache]}"
  else
    warn "~/.cache ya tiene bind mount activo"
  fi

  # ~/Downloads via symlink (más portable para apps)
  if [[ ! -L "$USER_DOWNLOADS" ]]; then
    [[ -d "$USER_DOWNLOADS" ]] && mv "$USER_DOWNLOADS" "${USER_DOWNLOADS}.bak.$$"
    ln -s "${DIRS[downloads]}" "$USER_DOWNLOADS"
    chown -h "${REAL_USER}:${REAL_USER}" "$USER_DOWNLOADS"
    ok "Downloads: ${C}${USER_DOWNLOADS}${N} → ${DIRS[downloads]}"
  else
    warn "~/Downloads ya es symlink, no se modifica"
  fi

  # Thumbnails
  mkdir -p "${DIRS[thumbnails]}"
  if ! mountpoint -q "$USER_THUMBS" 2>/dev/null; then
    mkdir -p "$USER_THUMBS"
    mount --bind "${DIRS[thumbnails]}" "$USER_THUMBS"
    ok "Thumbnails: ${C}${USER_THUMBS}${N} → ${DIRS[thumbnails]}"
  fi

  chown -R "${REAL_USER}:${REAL_USER}" "${DIRS[cache]}" "${DIRS[thumbnails]}"
}

# ── 5. Instalar servicio systemd (persistente entre reinicios) ─
install_service() {
  section "Instalando servicio systemd"

  PARTITION_ESC=$(systemd-escape --path "$PARTITION")
  SERVICE_FILE="/etc/systemd/system/usb-persist.service"

  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=USB-Persist: Redirigir temporales y caché al HDD
# Espera a que la partición esté disponible
After=local-fs.target
# Si la partición no existe, no falla el boot (nofail equivalente)
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
# Montar el HDD
ExecStart=/usr/bin/bash /usr/local/bin/usb-persist-mount.sh
ExecStop=/usr/bin/bash /usr/local/bin/usb-persist-
umount.sh

[Install]
WantedBy=multi-user.target
EOF

  # Script de montaje (llamado por el servicio)
  cat > /usr/local/bin/usb-persist-mount.sh <<MOUNTEOF
#!/usr/bin/env bash
# Auto-generado por usb-persist-setup.sh
# NO EDITAR MANUALMENTE

PARTITION="${PARTITION}"
MOUNT_POINT="${MOUNT_POINT}"
PERSIST_BASE="${PERSIST_BASE}"
REAL_USER="${REAL_USER}"
REAL_HOME="${REAL_HOME}"

# Verificar que la partición existe
if [[ ! -b "\$PARTITION" ]]; then
  echo "[usb-persist] Partición \$PARTITION no encontrada — saltando"
  exit 0
fi

mkdir -p "\$MOUNT_POINT"
mountpoint -q "\$MOUNT_POINT" || mount "\$PARTITION" "\$MOUNT_POINT"

# Crear dirs si no existen (primer uso en este PC)
mkdir -p "\${PERSIST_BASE}"/{tmp,var_tmp,cache/system,cache/browser,cache/thumbnails,downloads,logs,journal}
chmod 1777 "\${PERSIST_BASE}/tmp" "\${PERSIST_BASE}/var_tmp"
chown -R "\${REAL_USER}:\${REAL_USER}" "\${PERSIST_BASE}/cache" "\${PERSIST_BASE}/downloads"

# Bind mounts del sistema
mountpoint -q /tmp     || mount --bind "\${PERSIST_BASE}/tmp"     /tmp
mountpoint -q /var/tmp || mount --bind "\${PERSIST_BASE}/var_tmp" /var/tmp
mountpoint -q /var/log/journal || mount --bind "\${PERSIST_BASE}/journal /var/log/journal"
mountpoint -q /var/log || mount --bind "\${PERSIST_BASE}/logs /var/log"

# Bind mounts del usuario
mkdir -p "\${REAL_HOME}/.cache"
mountpoint -q "\${REAL_HOME}/.cache" || \
  mount --bind "\${PERSIST_BASE}/cache/system" "\${REAL_HOME}/.cache"

mkdir -p "\${REAL_HOME}/.cache/thumbnails"
mountpoint -q "\${REAL_HOME}/.cache/thumbnails" || \
  mount --bind "\${PERSIST_BASE}/cache/thumbnails" "\${REAL_HOME}/.cache/thumbnails"

# Symlink Downloads si no existe
[[ -L "\${REAL_HOME}/Downloads" ]] || \
  ln -sf "\${PERSIST_BASE}/downloads" "\${REAL_HOME}/Downloads"

chown -h "\${REAL_USER}:\${REAL_USER}" "\${REAL_HOME}/Downloads"
echo "[usb-persist] Montajes aplicados correctamente"
MOUNTEOF

  # Script de desmontaje limpio
  cat > /usr/local/bin/usb-persist-umount.sh <<UMOUNTEOF
#!/usr/bin/env bash
REAL_HOME="${REAL_HOME}"
MOUNT_POINT="${MOUNT_POINT}"

umount "\${REAL_HOME}/.cache/thumbnails" 2>/dev/null || true
umount "\${REAL_HOME}/.cache"            2>/dev/null || true
umount /var/tmp                          2>/dev/null || true
umount /tmp                              2>/dev/null || true
umount "\${MOUNT_POINT}"                 2>/dev/null || true
echo "[usb-persist] Desmontaje limpio completado"
UMOUNTEOF

  chmod +x /usr/local/bin/usb-persist-mount.sh
  chmod +x /usr/local/bin/usb-persist-umount.sh

  systemctl daemon-reload
  systemctl enable usb-persist.service
  ok "Servicio systemd instalado y habilitado"
}

# ── 6. Proteger /var/cache/pacman (excluir del scope) ────────
protect_pacman() {
  section "Protegiendo /var/cache/pacman (se queda en USB)"
  # Pacman ya usa /var/cache/pacman por defecto.
  # Solo verificamos que NO esté incluido en ningún bind mount.
  if mountpoint -q /var/cache 2>/dev/null; then
    warn "/var/cache tiene bind mount — desmontando para proteger pacman"
    umount /var/cache
  fi
  ok "/var/cache/pacman seguro en el USB"
}

# ── 7. Resumen final ─────────────────────────────────────────
show_summary() {
  section "Resumen"
  echo
  echo -e "  ${W}Partición HDD:${N}    ${C}${PARTITION}${N}"
  echo -e "  ${W}Montada en:${N}       ${C}${MOUNT_POINT}${N}"
  echo -e "  ${W}Base de datos:${N}    ${C}${PERSIST_BASE}${N}"
  echo
  echo -e "  ${W}Redirecciones activas:${N}"
  printf "  ${G}%-25s${N} → %s\n" "/tmp"                  "${DIRS[tmp]}"
  printf "  ${G}%-25s${N} → %s\n" "/var/tmp"              "${DIRS[var_tmp]}"
  printf "  ${G}%-25s${N} → %s\n" "~/.cache"              "${DIRS[cache]}"
  printf "  ${G}%-25s${N} → %s\n" "~/.cache/thumbnails"   "${DIRS[thumbnails]}"
  printf "  ${G}%-25s${N} → %s\n" "~/Downloads"           "${DIRS[downloads]}"
  echo
  echo -e "  ${W}Excluido (permanece en USB):${N}"
  printf "  ${Y}%-25s${N} sin cambios\n" "/var/cache/pacman"
  echo
  echo -e "  ${G}El servicio se activará automáticamente en cada reinicio.${N}"
  echo -e "  ${Y}Para forzar arranque manual:${N} systemctl start usb-persist"
  echo -e "  ${Y}Para ver estado:${N}            systemctl status usb-persist"
  echo -e "  ${Y}Para desinstalar:${N}           bash usb-persist-remove.sh"
  echo
}

# ── 8. Generar script de desinstalación ──────────────────────
generate_uninstaller() {
  cat > /usr/local/bin/usb-persist-remove.sh <<EOF
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
EOF
  chmod +x /usr/local/bin/usb-persist-remove.sh
  ok "Script de desinstalación: /usr/local/bin/usb-persist-remove.sh"
}

# ── MAIN ─────────────────────────────────────────────────────
main() {
  clear
  banner
  check_root
  get_partition "${1:-}"
  detect_user

  echo
  echo -e "  ${Y}¿Continuar con la configuración? [s/N]${N} \c"
  read -r CONFIRM
  [[ "$CONFIRM" =~ ^[sS]$ ]] || { echo -e "  ${R}Cancelado.${N}"; exit 0; }

  mount_hdd
  create_structure
  apply_bind_mounts
  apply_user_redirects
  protect_pacman
  install_service
  generate_uninstaller
  show_summary
}

main "$@"
