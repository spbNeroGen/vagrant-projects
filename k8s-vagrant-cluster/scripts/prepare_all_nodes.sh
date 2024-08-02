#!/bin/bash

# Отключаем SWAP и выключаем firewall (хотя на Debian он отключен из коробки)
echo "[Epic №1] - Disable Swap and firewall on All Nodes  "
sed -i '/swap/d' /etc/fstab       # Удаляем записи о SWAP из /etc/fstab
swapoff -a                        # Отключаем текущие SWAP-разделы
systemctl disable --now ufw >/dev/null 2>&1 # Останавливаем и отключаем ufw, подавляя вывод

# Включаем и загружаем модули ядра
echo "[Epic №2] - Kernel parameters"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
# Добавляем модули в конфигурационный файл
modprobe overlay              # Загружаем модуль overlay
modprobe br_netfilter         # Загружаем модуль br_netfilter

# Добавляем настройки ядра
echo "[Epic №3] - Kernel settings and changes into the effect"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
# Применяем настройки ядра
sysctl --system >/dev/null 2>&1                   # Обновляем параметры ядра, подавляя вывод

# Установка containerd
echo "[Epic №4] - Install containerd runtime"
export DEBIAN_FRONTEND=noninteractive             # Игнорируем вопросы конфигурации :)
apt-get update -qq >/dev/null                     # Обновляем списки пакетов в очень тихом режиме :)
apt-get install -qq -y apt-transport-https ca-certificates curl gnupg lsb-release >/dev/null
install -m 0755 -d /etc/apt/keyrings              # Создаем каталог для ключей
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc            # Устанавливаем права на файл ключа
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null  # Добавляем репозиторий Docker

apt-get update -qq >/dev/null
apt-get install -qq -y containerd.io >/dev/null
containerd config default > /etc/containerd/config.toml # Создаем конфигурацию containerd по умолчанию
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml # Включаем поддержку Systemd для cgroups
systemctl restart containerd                            # Перезапускаем containerd
systemctl enable containerd >/dev/null                  # Включаем автоматический запуск containerd, подавляя вывод

# Добавляем репозиторий Kubernetes
echo "[Epic №5] - Add kubernetes repo"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# Устанавливаем kubeadm, kubelet и kubectl
echo "[Epic №6] - Install kubeadm, kubelet and kubectl"
apt-get update -qq >/dev/null
apt-get install -qq -y kubeadm kubelet kubectl >/dev/null 
apt-mark hold -qq kubelet kubeadm kubectl # Блокируем обновления для установленных пакетов

# Включаем аутентификацию по паролю
echo "[Epic №7] - Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config 
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config # Разрешаем вход root пользователя по SSH

# Устанавливаем пароль root\root
echo "[Epic №8] - Set root password"
echo -e "root\nroot" | passwd root >/dev/null 2>&1 

# Обновляем файл /etc/hosts
echo "[Epic №9] - Add all hosts in /etc/hosts file" 
cat >>/etc/hosts<<EOF
172.30.0.100   m-node.stage.dev     m-node
172.30.0.101   w-node1.stage.dev    w-node1
172.30.0.102   w-node2.stage.dev    w-node2
EOF
