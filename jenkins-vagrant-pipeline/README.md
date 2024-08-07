## [jenkins-vagrant-pipeline](./)

- **Описание**: предназначен для автоматизированного развертывания Jenkins с настроенным агентом для CI/CD. Он включает в себя установку Jenkins Master на одном узле и подключение Jenkins Slave (агента) с другого узла, также имеется возможность предустановки Job и плагинов.

- **Образ Vagrant**: `generic/debian12` v4.3.12 - amd64 - VirtualBox  
  Ссылка на образ - [generic/debian12 на Vagrant Cloud](https://app.vagrantup.com/generic/boxes/debian12).  
  Добавить образ можно через команду `vagrant box add generic/debian12 <path-to-file>`.

## Содержание

1. [Предварительные требования](#предварительные-требования)
2. [Настройка Vagrant](#настройка-vagrant)
3. [Запуск и управление](#запуск-и-управление)
4. [Файлы проекта](#файлы-проекта)

## Предварительные требования

- Установлен [Vagrant](https://www.vagrantup.com/downloads)
- Установлен [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Настройка Vagrant

  **Добавление Vagrant Box**

   Сначала скачайте Vagrant Box `generic/debian12` и добавьте его с помощью команды:

   ```bash
   vagrant box add generic/debian12 <path-to-your-box-file>
   ```

## Запуск и управление

1. **Запуск виртуальной машины**

   Запустите виртуальную машину и выполните все шаги провизии с помощью команды:

   ```bash
   vagrant up
   ```

2. **Перезапуск провизии**

   Если вам нужно перезапустить процесс провизии, используйте:

   ```bash
   vagrant reload --provision
   ```

   Для выполнения только провизии без перезапуска виртуальной машины:

   ```bash
   vagrant provision
   ```

3. **Удаление и повторное создание виртуальной машины**

   Если требуется удалить текущую виртуальную машину и создать новую, используйте:

   ```bash
   vagrant destroy -f
   vagrant up
   ```

4. **Дашборд Jenkins**

   Jenkins Master будет доступен по адресу: `http://192.168.56.10:8080`

   Пароль для первого входа можно увидеть во время запуска `vagrant up`, либо подключиться к мастеру Jenkins командой  `vagrant ssh  j-master` и выполнить `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`

5. **Предустановка плагинов Jenkins**

    Вы можете предопределить список плагинов для установки, указав их через пробел в переменной `PLUGINS` файла `install-jenkins-master.sh` :

    ```bash
    PLUGINS="pipeline-aggregator-view git github gitlab-plugin workflow-step-api ssh-credentials docker-plugin kubernetes"
    ```

6. **Предустановка Job Pipeline**

    Для упрощения начальной настройки Jenkins, в проекте предусмотрена предустановленная задача пайплайна. Демонстрационная задача, которая служит примером для начала работы с пайплайнами в Jenkins. В переменно `PIPELINE_CONFIG` в файле `install-jenkins-master.sh`.
    Задача пайплайна включает три основных этапа: `Build, Test, и Deploy`, каждый из которых выводит сообщение в лог.

    ```bash
    PIPELINE_CONFIG='<?xml version="1.0" encoding="UTF-8"?>
    <flow-definition plugin="workflow-job@2.46">
    <actions/> ............................
    ```

## Файлы проекта

В каждом файле даны подробные комментарии на каждом шаге установки.

- `Vagrantfile` — конфигурационный файл Vagrant.
- `install-jenkins-master.sh` — конфигурационный файл Jenkins Master.
- `install-jenkins-slave.sh` — конфигурационный файл Jenkins Slave.
