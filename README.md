# Vagrant Projects

## Описание

В этом репозитории будут публиковаться различные проекты, демонстрирующие использование Vagrant для развертывания готовых сред. Эти проекты включают в себя предустановленные скрипты и конфигурации (shell и ansible), которые помогут быстро и эффективно развернуть виртуальные машины и настроить их для определенных нужд.

Проекты будут включать:

- **Vagrantfiles** - конфигурационные файлы для Vagrant, которые определяют, как создаются и настраиваются виртуальные машины.
- **Provisioning Scripts** - скрипты, которые автоматически настраивают виртуальные машины после их создания.
- **Примеры развертывания** - примеры настройки и запуска различных сред, таких как Kubernetes, веб-серверы и базы данных.

## Как использовать

1. **Клонируйте репозиторий**:

   ```bash
   git clone https://github.com/spbNeroGen/vagrant-projects.git
   ```

2. **Перейдите в директорию проекта**:

   ```bash
   cd vagrant-projects/<PATH-PROJECT>
   ```

3. **Запустите Vagrant**:

   ```bash
   vagrant up
   ```

## Проекты

### [k8s-vagrant-cluster](./k8s-vagrant-cluster)

- **Описание**: разворачивает кластер `Kubernetes` с помощью `kubeadm` (1 мастер и 2 воркера)

### [k8s-vagrant-cluster-mac-silicon](./k8s-vagrant-cluster-mac-silicon)

- **Описание**: разворачивает кластер `Kubernetes` с помощью `kubeadm`, специально адаптированный для работы на устройствах Mac с процессорами `Apple Silicon (M1/M2/M3)`.

### [microk8s-vm](./microk8s-vm)

- **Описание**: разворачивает `Microk8s`.

### [prometheus-vagrant-nodeexporter](./prometheus-vagrant-nodeexporter)

- **Описание**: разворачивает виртуальную машину, устанавливает `Docker` через `ansible`, запускает `docker compose` (поднимает `prometheus` + `grafana`, устанавливает нужный `dashboard`), а также настраивает `Node Exporter` для сборка метрик.

### [jenkins-vagrant-pipeline](./jenkins-vagrant-pipeline)

- **Описание**: разворачивает `Jenkins` с настроенным агентом для `CI/CD`. Включает в себя установку `Jenkins Master` на одном узле и подключение `Jenkins Slave` (агента) с другого узла через `jnlp`, а так же предустановка Job и плагинов.

### [postgresql-ha-cluster](./postgresql-ha-cluster)

- **Описание**: разворачивает кластерную архитектура `PostgreSQL` с использованием `ETCD`, `Patroni` и `HAProxy`.
