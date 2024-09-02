#!/bin/bash
env PIP_ROOT_USER_ACTION=ignore
# Отключаем SWAP и выключаем firewall (хотя на Debian он отключен из коробки)
echo "[Epic №1] "
sudo apt update

echo "[Epic №2] "
sudo apt -y install net-tools

echo "[Epic №3] "
sudo apt -y install postgresql postgresql-server-dev-15

echo "[Epic №4] "
sudo systemctl stop postgresql

echo "[Epic №5] "
sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

echo "[Epic №6] "
sudo apt -y install python-is-python3 python3-pip

echo "[Epic №7] "
sudo apt -y install python3-testresources   

echo "[Epic №8] "
sudo pip3 install --upgrade setuptools --break-system-packages

echo "[Epic №9] "
sudo pip3 install psycopg2 --break-system-packages

echo "[Epic №10] "
sudo pip3 install patroni --break-system-packages

echo "[Epic №11] "
sudo pip3 install python-etcd --break-system-packages

echo "[Epic №12] "
# Определение IP-адреса в подсети 192.168.50.
nodeN_ip=$(ip -o -4 addr show scope global | grep '192.168.50.' | awk '{print $4}' | cut -d'/' -f1)
# Остальные необходимые переменные
etcdnode_ip="192.168.50.20"
node1_ip="192.168.50.11"
node2_ip="192.168.50.12"
node3_ip="192.168.50.13"

if [[ "$nodeN_ip" == "192.168.50.11" ]]; then
  node_name="node1"
elif [[ "$nodeN_ip" == "192.168.50.12" ]]; then
  node_name="node2"
elif [[ "$nodeN_ip" == "192.168.50.13" ]]; then
  node_name="node3"
else
  echo "Неизвестный IP адрес: $nodeN_ip"
  exit 1
fi

echo "[Epic] - Add all hosts in /etc/hosts file" 
cat >>/etc/hosts<<EOF
192.168.50.11   node1.stage.dev     node1
192.168.50.12   node2.stage.dev     node2
192.168.50.13   node3.stage.dev     node3
192.168.50.20   etcdnode.stage.dev      etcdnode
192.168.50.30   haproxy.stage.dev      haproxy
EOF

# Файл конфигурации
patroni_config_file="/etc/patroni.yml"

# Создание резервной копии файла
#sudo cp $patroni_config_file $patroni_config_file.bak

# Полное замещение содержимого конфигурационного файла
sudo bash -c "cat > $patroni_config_file" <<EOF
scope: postgres
namespace: /db/
name: $node_name

restapi:
    listen: $nodeN_ip:8008
    connect_address: $nodeN_ip:8008

etcd:
    host: $etcdnode_ip:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator $node1_ip/0 md5
  - host replication replicator $node2_ip/0 md5
  - host replication replicator $node3_ip/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: $nodeN_ip:5432
  connect_address: $nodeN_ip:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
EOF

# Вывод обновленного файла для проверки
cat $patroni_config_file

echo "[Epic №13] "
# Создание директории для данных Patroni
sudo mkdir -p /data/patroni
sudo chown postgres:postgres /data/patroni
sudo chmod 700 /data/patroni

sudo bash -c "cat > /etc/systemd/system/patroni.service" <<EOF
[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd для применения нового сервиса
sudo systemctl daemon-reload

# Включение сервиса Patroni на автозапуск при загрузке системы
sudo systemctl enable patroni.service

# Запуск сервиса Patroni
sudo systemctl start patroni.service

# Проверка статуса сервиса Patroni
sudo systemctl status patroni.service