#!/bin/bash
# Присоединение к кластеру
echo "[Epic №1] - Join in cluster"
export DEBIAN_FRONTEND=noninteractive               # Устанавливаем переменную окружения для предотвращения интерактивного режима установки пакетов
apt-get install -qq -y sshpass >/dev/null           # Устанавливаем утилиту sshpass для автоматизации SSH-подключений с паролем

# Копируем скрипт присоединения из мастер-ноды на текущую ноду и выполняем его
sshpass -p "root" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no m-node.stage.dev:/join.sh /join.sh >/dev/null 2>&1

# Выполняем скрипт присоединения
bash /join.sh >/dev/null
