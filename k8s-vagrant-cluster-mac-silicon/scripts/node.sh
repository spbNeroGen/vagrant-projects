#!/bin/bash
# Настройка рабочих узлов (Node servers)

set -euxo pipefail

config_path="/vagrant/configs"
# Путь к директории, где хранятся общие файлы конфигурации и скрипты, созданные на мастер-узле.

# === Присоединение к кластеру ===
/bin/bash $config_path/join.sh -v
# Выполняем скрипт присоединения к кластеру Kubernetes, который был сгенерирован на мастер-узле.
# Флаг `-v` включает вывод отладки.

# === Настройка kubectl для пользователя vagrant ===
sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
NODENAME=$(hostname -s)
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
EOF

