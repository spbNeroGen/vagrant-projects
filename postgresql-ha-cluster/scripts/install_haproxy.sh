#!/bin/bash
echo "[Epic №1] "
sudo apt update

echo "[Epic №2] "
sudo apt -y install net-tools

echo "[Epic №3] "
sudo apt -y install haproxy

echo "[Epic] - Add all hosts in /etc/hosts file" 
cat >>/etc/hosts<<EOF
192.168.50.11   node1.stage.dev     node1
192.168.50.12   node2.stage.dev     node2
192.168.50.13   node3.stage.dev     node3
192.168.50.20   etcdnode.stage.dev      etcdnode
192.168.50.30   haproxy.stage.dev      haproxy
EOF

echo "[Epic №4] "
node1_ip="192.168.50.11"
node2_ip="192.168.50.12"
node3_ip="192.168.50.13"

haproxy_config_file="/etc/haproxy/haproxy.cfg"

sudo bash -c "cat > $haproxy_config_file" <<EOF
global
    maxconn 100
    log 127.0.0.1 local2

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

# Раздел для статистики
listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

# Frontend для PostgreSQL запросов
frontend postgres
    bind *:5000
    acl is_write method POST PUT DELETE PATCH CONNECT TRACE
    use_backend pg_write if is_write           
    default_backend pg_read                    

# Backend для запросов на запись (только Leader)
backend pg_write
    option httpchk OPTIONS /master
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node1 $node1_ip:5432 maxconn 100 check port 8008
    server node2 $node2_ip:5432 maxconn 100 check port 8008
    server node3 $node3_ip:5432 maxconn 100 check port 8008

# Backend для запросов на чтение (Replicas и Leader)
backend pg_read
    option httpchk OPTIONS /replica
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node1 $node1_ip:5432 maxconn 100 check port 8008
    server node2 $node2_ip:5432 maxconn 100 check port 8008
    server node3 $node3_ip:5432 maxconn 100 check port 8008
    
EOF

# Перезапуск HAProxy для применения новых настроек
sudo systemctl restart haproxy

# Проверка статуса HAProxy
sudo systemctl status haproxy