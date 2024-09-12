## [microk8s-vm](./)

- **Описание**: разворачивает `Microk8s` на ОС `Debian12`, предустанавливает helm и kubectl. Изменить версию можно в скрипте `HELM_VERSION` и `MICROK8S_VERSION`

- **Как использовать**:
  1. **Клонируйте репозиторий**:

     ```bash
     git clone https://github.com/nerogen92/vagrant-projects.git
     ```

  2. **Перейдите в директорию проекта**:

     ```bash
     cd vagrant-projects/microk8s-vm
     ```

  3. **Запустите Vagrant**:

     ```bash
     vagrant up
     ```

  4. **После успешного развертывания**:

        - Вы можете подключиться к **`VM`** с помощью:

        ```bash
        vagrant ssh
        ```

        - Тест работоспособности:

        ```bash
        vagrant@microk8s:~$ kubectl get nodes -o wide
        ```

      | NAME     | STATUS | ROLES | AGE   | VERSION | INTERNAL-IP | EXTERNAL-IP | OS-IMAGE                        | KERNEL-VERSION   | CONTAINER-RUNTIME        |
      |----------|--------|-------|-------|---------|-------------|-------------|---------------------------------|------------------|--------------------------|
      | microk8s | Ready  | <none> | 4h55m | v1.31.0 | 10.0.2.15   | <none>      | Debian GNU/Linux 12 (bookworm)   | 6.1.0-17-amd64   | containerd://1.6.28      |

        ```bash
        vagrant@microk8s:~$ kubectl get pods --all-namespaces
        ```

      | NAMESPACE            | NAME                                         | READY | STATUS  | RESTARTS         | AGE   |
      |----------------------|----------------------------------------------|-------|---------|------------------|-------|
      | container-registry   | registry-766d4b9987-bwk5j                    | 1/1   | Running | 1 (71m ago)      | 4h57m |
      | default              | nginx                                        | 1/1   | Running | 0                | 12m   |
      | ingress              | nginx-ingress-microk8s-controller-44gx4      | 1/1   | Running | 1 (71m ago)      | 4h59m |
      | kube-system          | calico-kube-controllers-759cd8b574-w4vqq     | 1/1   | Running | 1 (71m ago)      | 5h2m  |
      | kube-system          | calico-node-4fkp8                            | 1/1   | Running | 1 (71m ago)      | 5h2m  |
      | kube-system          | coredns-7896dbf49-fdfcg                      | 1/1   | Running | 1 (71m ago)      | 5h2m  |
      | kube-system          | dashboard-metrics-scraper-6b96ff7878-c4ndj   | 1/1   | Running | 1 (71m ago)      | 5h    |
      | kube-system          | hostpath-provisioner-5fbc49d86c-kjsnz        | 1/1   | Running | 1 (71m ago)      | 4h58m |
      | kube-system          | kubernetes-dashboard-7d869bcd96-4d2qm        | 1/1   | Running | 1 (71m ago)      | 5h    |
      | kube-system          | metrics-server-df8dbf7f5-8bwnq               | 1/1   | Running | 1 (71m ago)      | 5h    |

        - Пример деплоя **nginx**:

        ```bash
         kubectl run nginx --image=nginx --port=80 --restart=Never
        ```

  6. **Завершение работы**:

        ```bash
        exit
        vagrant halt
        ```
