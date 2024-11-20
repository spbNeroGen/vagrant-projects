## [k8s-vagrant-cluster-mac-silicon](./)

- **Описание**: проект разворачивает кластер `Kubernetes` с помощью `kubeadm`, специально адаптированный для работы на устройствах `Mac` с процессорами `Apple Silicon (M1/M2/M3`). Включает один мастер-узел и два рабочих узла. Используется `Vagrant` совместно с `VMware Fusion` для создания и настройки виртуальных машин.
`Virtual Box` не работает должным образом и нет хороших `VAGRANT`-боксов на базе `ARM`, которые поддерживают `Virtual Box`.

- **Образ Vagrant**: `bento/ubuntu-22.04` - arm64 - VMware Fusion  
  Ссылка на образ - [bento/ubuntu-22.04](https://portal.cloud.hashicorp.com/vagrant/discover/bento/ubuntu-22.04/versions/202401.31.0).  

  Добавить образ можно через команду:  
      ```bash
      vagrant box add bento/ubuntu-22.04 --provider=vmware_desktop
      ```

- **Конфигурация**:
  - **Мастер-узел** - узел для управления кластером Kubernetes.
  - **Рабочие узлы** - узлы для выполнения контейнерных приложений.
  - **Сетевой плагин** - используется [Calico](https://docs.tigera.io/calico/latest/about/) для настройки сети.

- **Особенности**:
  - Адаптация под архитектуру `ARM64`, необходимую для `Apple Silicon`.
  - Использование `VMware Fusion` для совместимости с `Mac M1/M2/M3`.
  - Включены оптимизации для стабильной работы на виртуальных машинах с ограниченными ресурсами.

- **Как использовать**:
  1. **Установите необходимые инструменты**:
     - VMware [Fusion](https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Fusion).
     - Vagrant [VMware Utility](https://developer.hashicorp.com/vagrant/install/vmware)
     - Vagrant и плагин `vagrant-vmware-desktop`.

      Установить плагин можно через команду: `vagrant plugin install vagrant-vmware-desktop`

  2. **Запустите Vagrant**:
       ```bash
       vagrant up
       ```

  3. **Подключитесь к мастер-узлу**:
       ```bash
       vagrant ssh controlplane
       ```

  4. **Проверьте состояние кластера**:
       ```bash
       kubectl get nodes -o wide
       ```

- **Пример развертывания nginx**:
  1. **Создайте Pod с nginx**:
       ```bash
       kubectl run nginx --image=nginx --port=80 --restart=Never
       ```

  2. **Создайте сервис для Pod**:
       ```bash
       kubectl expose pod nginx --port=80 --type=NodePort
       ```

  3. **Получите NodePort и доступ к сервису**:
       ```bash
       kubectl get svc nginx
       ```

- **Примечания**:
  - Убедитесь, что у вас установлены VMware Fusion и соответствующий плагин для Vagrant.
  - Скрипты настройки находятся в директории `scripts` и выполняются автоматически при запуске `vagrant up`.
