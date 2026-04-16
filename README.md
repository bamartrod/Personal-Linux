# Personal-Linux

 🚀 Resumen del Entorno de Ejecución - Arch Linux Ultra-Lite

Este documento contiene la especificación técnica del sistema optimizado para el rol de **Arquitecto Backend Senior (Microservicios & Cloud)**.

---

## 💻 Hardware Detectado
- **CPU/RAM**: Sistema optimizado para **4GB de RAM** con gestión de memoria agresiva.
- **Almacenamiento Primario (sde)**: USB de 15GB (Sistema Raíz /).
- **Almacenamiento Secundario (sdf)**: HDD de 1TB (Persistencia de datos y caché).
- **GPU / Video**: Soporte para aceleración por hardware Intel/Mesa.
- **Pantallas**: Dual Setup (HDMI-1 Principal + VGA-1 Extendida a la izquierda).
- **Periféricos**: Ratón vertical inalámbrico (2.4GHz) y teclado multimedia.

---

## 🛠️ Stack de Software & Entorno
- **OS**: Arch Linux (Rolling Release).
- **Kernel**: 6.19.11-arch1-1.
- **Window Manager**: i3wm (configuración minimalista).
- **Terminal**: Alacritty
- **Shell**: Zsh + Oh-My-Zsh (Powerlevel10k).
- **Audio**: PipeWire

---

## 🔧 Optimizaciones Específicas

### 1. Gestión de Recursos (RAM/CPU)
- **Firefox-Lite**: Limitado a 1 solo proceso de contenido, caché de RAM de 50MB y sin telemetría/animaciones.
- **ZRAM**: 1.9GB de Swap comprimido en RAM para maximizar los 4GB físicos.
- **USB-Persist**: La carpeta `~/.cache` está vinculada mediante *bind mount* al disco **sdf3** (HDD) para evitar llenar la USB de sistema.

### 2. Desarrollo (IDE & IA)
- **Neovim (IDE)**: Configurado para **Java (Spring Boot/Gradle)** y **Python**.
- **IA (Backend Architect)**: Configurada experta en protocolos (TCP/IP, gRPC, Kafka y AMQP), Cloud (AWS/Azure) y arquitectura limpia.

### 3. Utilidades QoL (Calidad de Vida)
- **Multimedia**: VLC (video), nsxiv (imágenes), zathura (PDF) - todos seleccionados por su bajo consumo.
- **Capturas**: [Impr Pant] captura solo el workspace activo (Sin barra de estado) y lo copia al portapapeles.

---

## ⌨️ Comandos Personalizados (Bash/Zsh)
- `clean-sde`: Limpieza profunda de paquetes, logs y basura en la USB principal.
- `fix-mounts`: Re-aplica los montajes de persistencia hacia el HDD.
- `reload-persist`: Recarga la configuración del shell y aplica los montajes.

## Installs
´´´
pacman -S alacritty=0.17.0-1 base=3-3 base-devel=1-2 curl=8.19.0-1 dmenu=5.4-1 dosfstools=4.2-5 efibootmgr=18-3 feh=3.12.1-1 firefox=149.0.2-1 foremost=1.5.7-7 git=2.53.0-1 github=cli 2.89.0-1 gradle=9.4.1-1 grub=2:2.14-1 htop=3.5.0-1 i3-wm=4.25.1-1 i3lock=2.16-1 i3status=2.15-1 inotify-tools=4.25.9.0-1 intel-gmmlib=22.9.0-2 iotop=0.6-13 jdk21-openjdk=21.0.10.u7-1 jq=1.8.1-1 libdisplay-info=0.3.0-1 libva-intel-driver=2.4.1-6 libxv=1.0.13-1 libxvmc=1.0.15-1 linux=6.19.11.arch1-1 linux- irmware=20260309-1 maim=5.8.1-3 mesa-utils=9.0.0-7 nano=9.0-1 neovim=0.12.1-1 networkmanager=1.56.0-1 nodejs=25.9.0-1 noto-fonts=1:2026.04.01-1 npm=11.12.1-1 nsxiv=34-1 ntfs-3g=2022.10.3-2 os-prober=1.84-1 parted=3.7-1 pipewire=1:1.6.3-1 pipewire-alsa=1:1.6.3-1 pipewire-jack=1:1.6.3-1 pipewire-pulse=1:1.6.3-1 profile-sync-daemon=1:7.03-1 python=3.14.4-1 python-pip=26.0.1-1 seatd=0.9.3-1 smartmontools=7.5-1 sudo=1.9.17.p2-2 sysstat=12.7.9-1 timeshift=25.12.4-1 tmux=3.6_a-1 ttf-jetbrains-mono=2.304-2 unzip=6.0-23 usbutils=019-1 vlc=3.0.22-3 vulkan-icd-loader=1.4.341.0-1 vulkan-intel=1:26.0.4-1 vulkan-mesa-implicit-layers=1:26.0.4-1 wget=1.25.0-3 xclip=0.13-6 xdg-utils=1.2.1-2 xdotool=4.20260303.1-1 xorg-server=21.1.21-1 xorg-xinit=1.4.4-1 xorg-xrandr=1.5.3-1 xorg-xset=1.2.5-2 athura=2026.03.27-1 zathura-pdf-mupdf=2026.02.03-6 zram-generator=1.2.1-1
´´Bash

