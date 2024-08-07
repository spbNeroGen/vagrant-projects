#!/bin/bash
# Installs Jenkins Master
export DEBIAN_FRONTEND=noninteractive             # Игнорируем вопросы конфигурации :)

# Epic #1  Загружаем и добавляем GPG ключ Jenkins для обеспечения подлинности пакетов
echo "[Epic #1] - Add Jenkins GPG key and repository"
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
# Добавляем репозиторий Jenkins в список источников пакетов
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list

# Epic #2 - Обновление индекса пакетов и установка Jenkins
echo "[Epic #2] - Update package index and install Jenkins"
sudo apt-get update -qq >/dev/null
sudo apt-get install -qq -y fontconfig openjdk-17-jre jenkins ca-certificates sshpass jq >/dev/null

# Epic #3 - Конфигурация параметров JAVA_ARGS для Jenkins
echo "[Epic #3] - Configure Jenkins JAVA_ARGS"
# Указываем путь к файлу конфигурации Jenkins
JENKINS_CONFIG_FILE="/etc/default/jenkins"
# Задаем новые значения для параметров JAVA_ARGS
JAVA_ARGS="-Djava.awt.headless=true -Xmx2048m -Djava.net.preferIPv4Stack=true"
# Проверяем, существует ли уже строка, начинающаяся с "JAVA_ARGS=" в конфигурационном файле
if sudo grep -q "^JAVA_ARGS=" "$JENKINS_CONFIG_FILE"; then
  # Если строка существует, заменяем её на новую с помощью sed
  # ^JAVA_ARGS= - соответствует строкам, начинающимся с "JAVA_ARGS="
  # .* - соответствует любому набору символов после "JAVA_ARGS="
  # s|^JAVA_ARGS=.*|JAVA_ARGS=\"$JAVA_ARGS\"| - заменяет строку на новую, где $JAVA_ARGS будет экранирован в двойные кавычки
  sudo sed -i "s|^JAVA_ARGS=.*|JAVA_ARGS=\"$JAVA_ARGS\"|" "$JENKINS_CONFIG_FILE"
else
  # Если строка не найдена, добавляем новую строку в конец конфигурационного файла
  # echo "JAVA_ARGS=\"$JAVA_ARGS\"" - добавляет строку с новыми значениями JAVA_ARGS
  # >> "$JENKINS_CONFIG_FILE" - перенаправляет вывод команды echo в файл, добавляя строку в конец
  echo "JAVA_ARGS=\"$JAVA_ARGS\"" >> "$JENKINS_CONFIG_FILE"
fi

# Epic #4 - Запуск сервиса Jenkins
echo "[Epic #4] - Start Jenkins service"
sudo adduser vagrant jenkins >/dev/null
sudo systemctl enable jenkins >/dev/null   
sudo systemctl daemon-reload >/dev/null
sudo systemctl restart jenkins >/dev/null

# Epic #5 - Ожидание запуска Jenkins
echo "[Epic #5] - Waiting for Jenkins to start"
# Здесь можно добавить задержку, если необходимо, чтобы Jenkins полностью запустился
# sleep 30

# Epic #6 - Загрузка Jenkins CLI и получение токена
echo "[Epic #6] - Download Jenkins CLI and token pi"
JENKINS_URL="http://192.168.56.10:8080"
JENKINS_CLI="/usr/share/jenkins/jenkins-cli.jar"

# Определяем учетные данные администратора Jenkins
JENKINS_USER=admin
JENKINS_USER_PASS=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Загружаем CLI Jenkins
sudo wget -O $JENKINS_CLI $JENKINS_URL/jnlpJars/jenkins-cli.jar > /dev/null 2>&1

# Получаем crumb для предотвращения CSRF атак
JENKINS_CRUMB=$(curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -s --cookie-jar /tmp/cookies $JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
# Создаем новый токен для API для администратора
ACCESS_TOKEN=$(curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -H $JENKINS_CRUMB -s \
                    --cookie /tmp/cookies $JENKINS_URL'/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken' \
                    --data 'newTokenName=GlobalToken' | jq -r '.data.tokenValue')

# Epic #7 - Установка рекомендованных плагинов
echo "[Epic #7] - Install recommended plugins" 
# Определяем список плагинов для установки, указываем через пробел необходимые
PLUGINS="pipeline-aggregator-view workflow-cps jersey2-api git github gitlab-plugin workflow-step-api ssh-credentials docker-plugin kubernetes"
for PLUGIN in $PLUGINS; do
    echo "Installing plugin: $PLUGIN"
    # Устанавливаем каждый плагин и разворачиваем его
    java -jar $JENKINS_CLI -s $JENKINS_URL -auth admin:$JENKINS_USER_PASS install-plugin $PLUGIN -deploy
done

# Epic #8 - Создаем и конфигурируем агента Jenkins
echo "[Epic #8] - Configure Jenkins agent"
# Определяем имя для агента
NODE_NAME="jenkins-slave"
# Создаем конфигурацию для нового агента Jenkins
java -jar $JENKINS_CLI -s $JENKINS_URL -auth admin:$JENKINS_USER_PASS create-node $NODE_NAME <<EOF
<slave>
  <name>jenkins-slave</name>
  <description>Jenkins agent</description>
  <remoteFS>/home/jenkins</remoteFS>
  <numExecutors>2</numExecutors>
  <launcher class="hudson.slaves.JNLPLauncher">
    <workDirSettings>
      <disabled>false</disabled>
      <internalDir>remoting</internalDir>
      <failIfWorkDirIsMissing>false</failIfWorkDirIsMissing>
    </workDirSettings>
    <webSocket>false</webSocket>
  </launcher>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <nodeProperties/>
</slave>
EOF

# Путь к файлу конфигурации Jenkins
JENKINS_CONFIG_FILE="/var/lib/jenkins/config.xml"
# порт для агентов
AGENT_PORT="50000"
# Проверяем, существует ли строка <slaveAgentPort>
if sudo grep -q "<slaveAgentPort>" "$JENKINS_CONFIG_FILE"; then
  # Если строка существует, заменяем её на новую
  sudo sed -i "s|<slaveAgentPort>.*</slaveAgentPort>|<slaveAgentPort>$AGENT_PORT</slaveAgentPort>|" "$JENKINS_CONFIG_FILE"
else
  # Если строки нет, добавляем её перед </hudson>
  sudo sed -i "/<\/hudson>/i <slaveAgentPort>$AGENT_PORT</slaveAgentPort>" "$JENKINS_CONFIG_FILE"
fi

# Epic #9 - Получение секрета для узла агента
echo "[Epic #9] - Get secret for node slave"
# Выполняем Groovy скрипт для получения секрета для созданного агента "jenkins-slave"
echo 'import jenkins.model.*; import hudson.slaves.*; def jenkins = Jenkins.instance; def nodeName = "jenkins-slave"; def node = jenkins.getNode(nodeName); if (node != null) { def secret = node.getComputer().getJnlpMac(); println("${secret}"); } else { println("Node '${nodeName}' not found."); }' > /tmp/get-node-secret.groovy

SECRET=$(curl -s -X POST "$JENKINS_URL/scriptText" \
  --user admin:$ACCESS_TOKEN \
  --data-urlencode "script=$(< /tmp/get-node-secret.groovy)")

# Выводим полученный секрет и пароль администратора
echo "Secret node jenkins-slave:"
echo "$(echo $SECRET)"
echo "Admin pass:"
echo "$(echo $JENKINS_USER_PASS)"

# Epic #10 - Добавляем тестовую Job с pipeline
echo "[Epic #10] - TEST PIPELINE ADD"
PIPELINE_CONFIG='<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.46">
  <actions/>
  <description>Example Pipeline Job</description>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.1077.vb_74b_a_05c6">
    <script>pipeline {
      agent any
      stages {
        stage('Build') {
          steps {
            echo 'Building...'
          }
        }
        stage('Test') {
          steps {
            echo 'Testing...'
          }
        }
        stage('Deploy') {
          steps {
            echo 'Deploying...'
          }
        }
      }
    }</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <disabled>false</disabled>
</flow-definition>'
# Создайте пайплайн задачу
echo "$PIPELINE_CONFIG" | java -jar $JENKINS_CLI -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_USER_PASS create-job my-pipeline

# Epic #11 - Подготовка файла .service для агента Jenkins
echo "[Epic #11] - Prepare file .service for agent jenkins slave"
# Создаем скрипт запуска агента Jenkins
cat <<EOL > /jenkins-agent.sh
#!/bin/bash
# Запуск Jenkins Agent
java -jar /usr/local/bin/jenkins-agent.jar -url "$JENKINS_URL" -secret "$SECRET" -name "$NODE_NAME" -workDir "/home/jenkins"
EOL
# Создаем .service для запуска агента Jenkins
cat <<EOL > /jenkins-agent.service
[Unit]
Description=Jenkins Agent Service
After=network.target

[Service]
ExecStart=/usr/local/bin/jenkins-agent.sh
Restart=always
User=vagrant
Group=vagrant
Environment="JENKINS_URL=$JENKINS_URL"
Environment="NODE_NAME=$NODE_NAME"
Environment="SECRET=$SECRET"

[Install]
WantedBy=multi-user.target
EOL

# Epic #12 - Включение аутентификации по паролю для SSH
echo "[Epic №12] - Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config 
# Разрешаем вход root пользователя по SSH
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# Epic #13 - Установка пароля для root
echo "[Epic №13] - Set root password"
echo -e "root\nroot" | passwd root >/dev/null 2>&1 

# Epic #14 - Добавление всех хостов в файл /etc/hosts
echo "[Epic №14] - Add all hosts in /etc/hosts file" 
cat >>/etc/hosts<<EOF
192.168.56.10   j-master.stage.dev     j-master
192.168.56.11   j-slave.stage.dev    j-slave
EOF

# Epic #15 - Перезагрузка Jenkins
echo "[Epic #15] - Restart Jenkins"
sudo systemctl restart jenkins
