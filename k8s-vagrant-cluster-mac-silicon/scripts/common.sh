#!/bin/bash
# Общая настройка для всех серверов (Control plane и nodes)

set -euxo pipefail
# Настройка строгого режима для выполнения скрипта:
# `-e`: завершить скрипт при ошибке любой команды
# `-u`: считать необъявленные переменные ошибкой
# `-x`: выводить команды перед выполнением
# `-o pipefail`: обрабатывать ошибки в конвейерах

# === Настройка DNS ===
if [ ! -d /etc/systemd/resolved.conf.d ]; then
    sudo mkdir /etc/systemd/resolved.conf.d/
fi

# Создаем файл конфигурации DNS и записываем указанные серверы
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

# Перезапуск службы systemd-resolved для применения изменений
sudo systemctl restart systemd-resolved

# === Отключение Swap ===
sudo swapoff -a # Отключаем swap для работы Kubernetes
# Добавляем команду отключения swap при перезагрузке системы
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

sudo apt-get update -y # Обновляем список пакетов

# === Загрузка модулей ядра для Kubernetes ===
# Создаем файл для автозагрузки модулей при старте системы
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Загружаем модули ядра
sudo modprobe overlay
sudo modprobe br_netfilter

# === Настройка параметров sysctl для Kubernetes ===
# Создаем файл с настройками сети, чтобы включить форвардинг пакетов и настройку iptables
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Применяем настройки sysctl без перезагрузки
sudo sysctl --system

# === Установка CRI-O Runtime ===
sudo apt-get update -y
apt-get install -y software-properties-common curl apt-transport-https ca-certificates

# Добавляем ключи и репозиторий для CRI-O
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o # Устанавливаем CRI-O

# Включаем и запускаем службу CRI-O
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

echo "CRI runtime installed successfully"

# === Установка Kubernetes компонентов ===
sudo mkdir -p /etc/apt/keyrings
# Добавляем ключи и репозиторий Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Устанавливаем kubelet, kubeadm и kubectl
sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get update -y
sudo apt-get install -y jq

# === Настройка kubelet ===
# Определяем локальный IP-адрес для узла
local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"

# Конфигурируем дополнительные параметры для kubelet
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF
