#!/bin/bash
echo "[Epic №1] "
sudo apt update

echo "[Epic №2] "
sudo apt -y install net-tools

echo "[Epic №3] "
sudo apt -y install etcd-server
sudo apt -y install etcd-client

echo "[Epic] - Add all hosts in /etc/hosts file" 
cat >>/etc/hosts<<EOF
192.168.50.11   node1.stage.dev     node1
192.168.50.12   node2.stage.dev     node2
192.168.50.13   node3.stage.dev     node3
192.168.50.20   etcdnode.stage.dev      etcdnode
192.168.50.30   haproxy.stage.dev      haproxy
EOF

echo "[Epic №4] "
# Переменная для IP-адреса etcd узла
etcdnode_ip="192.168.50.20"

# Файл конфигурации
etcd_config_file="/etc/default/etcd"

# Полное замещение содержимого конфигурационного файла etcd
sudo bash -c "cat > $etcd_config_file" <<EOF
ETCD_LISTEN_PEER_URLS="http://$etcdnode_ip:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://$etcdnode_ip:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$etcdnode_ip:2380"
ETCD_INITIAL_CLUSTER="default=http://$etcdnode_ip:2380,"
ETCD_ADVERTISE_CLIENT_URLS="http://$etcdnode_ip:2379"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

# Файл unit-файла etcd.service
etcd_service_file="/lib/systemd/system/etcd.service"

# Добавление флага --enable-v2=true к строке ExecStart
sudo sed -i '/^ExecStart=/ s/$/ --enable-v2=true/' $etcd_service_file

echo "[Epic №5] "

# Перезагрузка systemd для применения нового сервиса
sudo systemctl daemon-reload

# Включение сервиса Patroni на автозапуск при загрузке системы
sudo systemctl enable etcd

# Перезапуск etcd
sudo systemctl restart etcd

echo "[Epic №6] "
# Проверка статуса etcd
sudo systemctl status etcd
