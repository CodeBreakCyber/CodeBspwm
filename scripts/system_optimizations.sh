#!/usr/bin/env bash

#==============================================================================
# Optimizaciones del Sistema
# Mejora el rendimiento general del sistema
#==============================================================================

set -e

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECK="${GREEN}✓${NC}"
ARROW="${CYAN}➜${NC}"
INFO="${CYAN}ℹ${NC}"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           System Performance Optimizations               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${ARROW} Aplicando optimizaciones del sistema...\n"

# Crear archivo de configuración sysctl
echo -e "${ARROW} Sintonizando parámetros del kernel (Optimización Avanzada)..."
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null <<EOF
# Optimización de Memoria y Swap
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Optimización de Red (Baja Latencia / Pentesting)
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_fastopen=3
net.core.netdev_max_backlog=5000

# Optimización de Programador (Responsividad del Desktop)
kernel.sched_autogroup_enabled=1

# Límites de archivos
fs.file-max=2097152
EOF

# MGLRU (Multi-Gen LRU) - Solo para Kernels 6.1+ 
# Mejora drásticamente el rendimiento bajo presión de memoria
echo 0x0007 > /sys/kernel/mm/lru_gen/enabled 2>/dev/null || true
echo -e "${CHECK} Parámetros del kernel configurados"

# Aplicar cambios
echo -e "${ARROW} Aplicando cambios en vivo..."
sudo sysctl -p /etc/sysctl.d/99-performance.conf > /dev/null
echo -e "${CHECK} Cambios aplicados"

# Instalar y configurar irqbalance
echo -e "${ARROW} Configurando irqbalance (Distribución de carga de núcleos)..."
if ! command -v irqbalance &> /dev/null; then
    sudo apt install -y irqbalance -qq
fi
sudo systemctl enable irqbalance &> /dev/null
sudo systemctl start irqbalance &> /dev/null
echo -e "${CHECK} irqbalance configurado y activo"

# Configurar CPU governor
if command -v cpupower &> /dev/null; then
    echo -e "${ARROW} Configurando perfil de energía: Performance..."
    sudo cpupower frequency-set -g performance > /dev/null
    echo -e "${CHECK} CPU governor configurado"
else
    echo -e "${YELLOW}ℹ${NC} Instalando herramientas de CPU..."
    sudo apt install -y linux-cpupower -qq
    sudo cpupower frequency-set -g performance > /dev/null 2>/dev/null || true
fi

# Configurar I/O scheduler para SSD/NVMe
echo -e "${ARROW} Optimizando I/O Schedulers..."
# shellcheck disable=SC2015
for disk in /sys/block/sd*/queue/scheduler; do
    if [ -f "$disk" ]; then
        echo "mq-deadline" | sudo tee "$disk" > /dev/null 2>&1 || true
    fi
done
# shellcheck disable=SC2015
for disk in /sys/block/nvme*/queue/scheduler; do
    if [ -f "$disk" ]; then
        echo "none" | sudo tee "$disk" > /dev/null 2>&1 || true
    fi
done
echo -e "${CHECK} I/O Schedulers optimizados"

# Crear servicio systemd persistente
echo -e "${ARROW} Asegurando persistencia de ajustes..."
sudo tee /etc/systemd/system/kali-performance.service > /dev/null <<'EOF'
[Unit]
Description=KaliBspwm Performance Tuning
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/kali-apply-tuning.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo tee /usr/local/bin/kali-apply-tuning.sh > /dev/null <<'EOF'
#!/bin/bash
# Re-aplicar I/O Schedulers
for disk in /sys/block/sd*/queue/scheduler; do [ -f "$disk" ] && echo "mq-deadline" > "$disk" 2>/dev/null; done
for disk in /sys/block/nvme*/queue/scheduler; do [ -f "$disk" ] && echo "none" > "$disk" 2>/dev/null; done
# Re-aplicar CPU Governor
command -v cpupower &>/dev/null && cpupower frequency-set -g performance >/dev/null
# Re-aplicar MGLRU
echo 0x0007 > /sys/kernel/mm/lru_gen/enabled 2>/dev/null || true
EOF

sudo chmod +x /usr/local/bin/kali-apply-tuning.sh
sudo systemctl enable kali-performance.service &>/dev/null
echo -e "${CHECK} Configuración persistente finalizada"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${CHECK} ${GREEN}Optimizaciones Profesionales Aplicadas!${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${INFO} ${CYAN}Resumen de cambios:${NC}"
echo -e "  ${ARROW} Red: BBR (Google Bottleneck Bandwidth) activo"
echo -e "  ${ARROW} Memoria: MGLRU (Multi-Gen LRU) activado para Kernel 6.1+"
echo -e "  ${ARROW} CPU: Perfil de alto rendimiento activo"
echo -e "  ${ARROW} Disco: I/O Optimizado (SSD/NVMe)"
echo -e "  ${ARROW} Multicore: irqbalance distribuirá la carga automáticamente"
echo ""
