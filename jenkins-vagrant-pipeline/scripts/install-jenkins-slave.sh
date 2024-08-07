#!/bin/bash
# Installs Jenkins Slave
# Epic №1 - Обновляем индекс пакетов и устанавливаем необходимые пакеты
echo "[Epic №1] - Join in Jenkins"
export DEBIAN_FRONTEND=noninteractive               
sudo apt-get update -qq
apt-get install -qq -y openjdk-17-jre wget sshpass jq >/dev/null   

# Epic №2 - Создаем директорию для агента Jenkins и устанавливаем права доступа
echo "[Epic №2] - Prepare dir /home/jenkins"
sudo mkdir -p /home/jenkins
sudo chown vagrant:vagrant /home/jenkins
sudo chmod 700 /home/jenkins

# Epic №3 - Скачиваем Jenkins Agent JAR файл с URL мастера и устанавливаем права на выполнение
echo "[Epic №3] - Download Jenkins Agent"
JENKINS_URL="http://192.168.56.10:8080"
sudo wget -O /usr/local/bin/jenkins-agent.jar $JENKINS_URL/jnlpJars/agent.jar > /dev/null 2>&1
sudo chmod +x /usr/local/bin/jenkins-agent.jar

# Epic №5 - Добавляем записи в файл /etc/hosts для разрешения имен
echo "[Epic №4] - Add all hosts in /etc/hosts file" 
cat >>/etc/hosts<<EOF
192.168.56.10   j-master.stage.dev     j-master
192.168.56.11   j-slave.stage.dev    j-slave
EOF

# Epic №5 - Копируем скрипт присоединения из мастера на текущую ноду и выполняем его
echo "[Epic №5] - Copy script from j-master" 
# Копируем скрипт присоединения агента
sshpass -p "root" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no j-master.stage.dev:/jenkins-agent.sh /usr/local/bin/jenkins-agent.sh >/dev/null 2>&1
sudo chmod +x /usr/local/bin/jenkins-agent.sh
# Копируем конфигурационный файл сервиса агента Jenkins
sshpass -p "root" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no j-master.stage.dev:/jenkins-agent.service /etc/systemd/system/jenkins-agent.service >/dev/null 2>&1

# Epic №6 - Перезагружаем конфигурацию systemd и включаем/перезапускаем сервис агента Jenkins
echo "[Epic №6] - Restart Jenkins agent" 
sudo systemctl daemon-reload
sudo systemctl enable jenkins-agent.service
sudo systemctl restart jenkins-agent.service
