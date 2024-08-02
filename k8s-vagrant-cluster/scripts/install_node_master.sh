#!/bin/bash
# Загружаем образы контейнеров, необходимые для запуска кластера Kubernetes
echo "[Epic №1] - Pull required containers"
kubeadm config images pull >/dev/null 

# Настраиваем и инициализируем кластер Kubernetes с указанным адресом API-сервера и CIDR для подов
echo "[Epic №2] - kubeadm init cluster" 
kubeadm init --apiserver-advertise-address=172.30.0.100 --pod-network-cidr=10.244.0.0/16 >> /root/kubeinit.log 2>/dev/null # Логи инициализации сохраняются в /root/kubeinit.log, вывод ошибок подавляется
# --apiserver-advertise-address указывает IP-адрес API-сервера
# --pod-network-cidr указывает CIDR для сети подов 

# Устанавливаем сетевой плагин Calico для управления сетевыми политиками и маршрутизацией в кластере
echo "[Epic №3] - Install Calico network v3.28.0"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml >/dev/null

# Создаем токен и генерируем команду для присоединения других узлов к кластеру, сохраняем ее в /joincluster.sh
echo "[Epic №4] - Generate and save cluster join command"
kubeadm token create --print-join-command > /join.sh
