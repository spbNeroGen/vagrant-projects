#!/bin/bash
# Настройка серверов Control Plane (мастер-узел)

set -euxo pipefail

NODENAME=$(hostname -s)

sudo kubeadm config images pull
# Загружаем все необходимые образы для Kubernetes.

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init \
  --apiserver-advertise-address=$CONTROL_IP \
  --apiserver-cert-extra-sans=$CONTROL_IP \
  --pod-network-cidr=$POD_CIDR \
  --service-cidr=$SERVICE_CIDR \
  --node-name "$NODENAME" \
  --ignore-preflight-errors Swap
# Инициализируем кластер Kubernetes с указанными параметрами:
# - `--apiserver-advertise-address`: IP-адрес для API-сервера.
# - `--apiserver-cert-extra-sans`: дополнительные IP-адреса для сертификатов API-сервера.
# - `--pod-network-cidr`: диапазон IP для подов.
# - `--service-cidr`: диапазон IP для сервисов.
# - `--node-name`: имя узла.
# - `--ignore-preflight-errors Swap`: игнорируем предупреждение о включенном swap.

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
# Настраиваем конфигурацию kubectl для текущего пользователя:
# - Копируем файл конфигурации Kubernetes (`admin.conf`) в домашнюю директорию.
# - Изменяем владельца файла на текущего пользователя.

# === Сохранение конфигураций для совместного использования ===
config_path="/vagrant/configs"
# Директория для сохранения конфигураций (используется Vagrant).

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi
# Если директория уже существует, очищаем её. Если нет — создаем.

cp -i /etc/kubernetes/admin.conf $config_path/config
# Копируем конфигурационный файл кластера в общую директорию.

touch $config_path/join.sh
chmod +x $config_path/join.sh
# Создаем скрипт для присоединения узлов к кластеру и делаем его исполняемым.

kubeadm token create --print-join-command > $config_path/join.sh
# Генерируем команду для присоединения узлов к кластеру и сохраняем её в `join.sh`.

# === Установка сетевого плагина Calico ===
curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O
# Скачиваем манифест Calico из репозитория.

kubectl apply -f calico.yaml
# Применяем манифест для установки Calico в кластер.

# === Настройка окружения пользователя vagrant ===
sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
echo "alias k='kubectl'" >> ~/.bashrc
EOF
# Выполняем действия от имени пользователя `vagrant`:
# - Создаем директорию `.kube`.
# - Копируем конфигурацию Kubernetes в директорию пользователя.
# - Устанавливаем правильные права доступа на файл.
# - Добавляем алиас `k` для `kubectl` в `.bashrc`.

# === Установка Metrics Server ===
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml
# Устанавливаем Metrics Server, который используется для сбора метрик кластера.
