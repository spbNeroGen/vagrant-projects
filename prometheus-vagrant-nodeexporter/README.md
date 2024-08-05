## [prometheus-vagrant-nodeexporter](./)

- **Описание**: использует Vagrant для создания и настройки виртуальной машины, на которой устанавливается Docker с помощью Ansible, запускается Docker Compose для установки и запуска Prometheus и Grafana, а также настраивается Node Exporter.

- **Образ Vagrant**: `generic/debian12` v4.3.12 - amd64 - VirtualBox  
  Ссылка на образ - [generic/debian12 на Vagrant Cloud](https://app.vagrantup.com/generic/boxes/debian12).
  
  Добавить образ можно через команду `vagrant box add generic/debian12 <path-to-file>`

## Содержание

1. [Предварительные требования](#предварительные-требования)
2. [Настройка Vagrant](#настройка-vagrant)
3. [Запуск и управление](#запуск-и-управление)
4. [Файлы проекта](#файлы-проекта)

## Предварительные требования

- Установлен [Vagrant](https://www.vagrantup.com/downloads)
- Установлен [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- Установлен [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) на хостовой системе; если хостовая система Windows можно использовать WSL, тогда необходимо отредактировать в WSL `~./bashrc` добавив:

    ```shell
  export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
  export VBOX_INSTALL_PATH="/mnt/c/Program Files/Oracle/VirtualBox"
  export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
  ```

- Обход ограничений на скачивание необходимого плагина:

  ```shell
  echo 'export http_proxy=http://<username>:<password>@<proxy-server>:<port>' >> ~/.bashrc
  echo 'export https_proxy=http://<username>:<password>@<proxy-server>:<port>' >> ~/.bashrc
  source ~/.bashrc
  ```

- Плагин для проброса с WSL на Windows возможности создания ВМ на хостовой машине - `vagrant plugin install virtualbox_WSL2`

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

- После запуска Grafana будет доступна по адресу: `http://192.168.56.10:3000`

## Файлы проекта

- `Vagrantfile` — конфигурационный файл Vagrant.
- `docker-compose.yml` — конфигурация Docker Compose для запуска Prometheus и Grafana.
- `prometheus/prometheus.yml` — конфигурация Prometheus.
- `dashboard.json` — JSON-файл с настройками дашборда для Grafana.
- `playbook.yml` — Ansible playbook для установки Docker и настройки сервиса.
