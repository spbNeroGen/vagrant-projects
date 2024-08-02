## [k8s-vagrant-cluster](./k8s-vagrant-cluster)

- **Описание**: проект разворачивает кластер Kubernetes с помощью `kubeadm`, включающий один мастер-узел и два рабочих узла. Он использует Vagrant для автоматического создания и настройки виртуальных машин с Debian 12, а также настройки Kubernetes кластера.

- **Образ Vagrant**: `generic/debian12` v4.3.12 - amd64 - VirtualBox  
  Ссылка на образ - [generic/debian12 на Vagrant Cloud](https://app.vagrantup.com/generic/boxes/debian12).
  
  Добавить образ можно через команду `vagrant box add generic/debian12 <path-to-file>`

- **Конфигурация**:
  - **Мастер-узел** - основной узел кластера, управляющий и координирующий работу рабочих узлов.
  - **Рабочие узлы** - узлы, на которых запускаются контейнеры.

- **Настройка Kubernetes**:
  - **Инициализация кластера** выполняется с помощью `kubeadm` на мастер-узле.
  - **Сетевой плагин** для настройки сетевого взаимодействия между узлами используется [Calico](https://docs.tigera.io/calico/latest/about/).
  - **Кубе конфиг** после инициализации кластера конфигурационный файл `kubeconfig` будет доступен на мастер-узле по пути `/etc/kubernetes/admin.conf`.

- **Как использовать**:
  1. **Клонируйте репозиторий**:

     ```bash
     git clone https://github.com/ваш-пользователь/vagrant-projects.git
     ```

  2. **Перейдите в директорию проекта**:

     ```bash
     cd vagrant-projects/k8s-vagrant-cluster
     ```

  3. **Запустите Vagrant**:

     ```bash
     vagrant up
     ```

  4. **После успешного развертывания**:
     - Вы можете подключиться к мастер-узлу с помощью:

       ```bash
       vagrant ssh m-node
       ```

     - Для доступа к `kubectl` на мастер-узле:

       ```bash
       kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes -o wide
       ```

      На выходе получаем:

      | NAME    | STATUS | ROLES         | AGE   | VERSION | INTERNAL-IP | OS-IMAGE                        | KERNEL-VERSION     | CONTAINER-RUNTIME   |
      |---------|--------|---------------|-------|---------|-------------|---------------------------------|--------------------|---------------------|
      | m-node  | Ready  | `control-plane` | 7m21s | v1.30.3| 172.30.0.100| Debian GNU/Linux 12 (bookworm) | 6.1.0-17-amd64     | containerd://1.7.19 |
      | w-node1 | Ready  | `<none>`        | 4m46s | v1.30.3| 172.30.0.101| Debian GNU/Linux 12 (bookworm) | 6.1.0-17-amd64     | containerd://1.7.19 |
      | w-node2 | Ready  | `<none>`      | 98s   | v1.30.3| 172.30.0.102| Debian GNU/Linux 12 (bookworm) | 6.1.0-17-amd64     | containerd://1.7.19 |



     - Чтобы подключиться к `kubectl` из вашего локального компьютера, скопируйте файл конфигурации `admin.conf` с мастер-узла на ваш локальный компьютер и настройте `.kube/config`
  5. **Пример развертывания nginx**:

       ```bash
      kubectl --kubeconfig=/etc/kubernetes/admin.conf run nginx --image=nginx --port=80 --restart=Never
      kubectl --kubeconfig=/etc/kubernetes/admin.conf expose pod nginx --port=80 --type=NodePort
       ```

      - **`kubectl run nginx --image=nginx --port=80 --restart=Never`** - создает Pod с именем `nginx`, используя образ `nginx` и открывает порт 80.
      - **`kubectl expose pod nginx --port=80 --type=NodePort`** создает сервис для Pod, чтобы открыть доступ через NodePort.

      Эта команда развернет Nginx и создаст сервис для доступа к нему. Вы можете проверить его работу, подключившись к NodePort на любой из ваших нод.

- **Примечания**:
  - Убедитесь, что у вас установлен **VirtualBox** и **Vagrant** перед началом работы. А также отключен брендмаур (может блокировать проброс порта 22 в VM)
  - Скрипты и конфигурационные файлы для настройки кластера находятся в директории `scripts` и будут автоматически выполнены при запуске `vagrant up`.

Эта конфигурация позволит быстро развернуть полностью функционирующий кластер Kubernetes для разработки и тестирования, не затрачивая много времени на ручную настройку.
