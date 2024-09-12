#!/bin/bash
HELM_VERSION=3.16.0
MICROK8S_VERSION=1.31

echo "[Epic №1] - Update Debian"
apt-get update
apt-get -y install snapd apt-transport-https jq bash-completion

echo "[Epic №2] - Add allias"
touch /home/vagrant/.bashrc
echo "alias kubectl='microk8s kubectl'" >> /home/vagrant/.bashrc
echo "alias k='microk8s kubectl'" >> /home/vagrant/.bashrc
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc

echo "[Epic №3] -  Disable Swap and firewall"
sed -i '/swap/d' /etc/fstab       
swapoff -a                        
systemctl disable --now ufw >/dev/null 2>&1 

echo "[Epic №4] -  Addnew nameserver"
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

echo "[Epic №5] - Install helm"
wget https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz
tar -xzf helm-v$HELM_VERSION-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm-v$HELM_VERSION-linux-amd64.tar.gz linux-amd64

echo "[Epic №6] - Install microk8s"
sudo snap install microk8s --classic --channel=$MICROK8S_VERSION/stable
sleep 120
/snap/bin/microk8s status --wait-ready
/snap/bin/microk8s enable dns
/snap/bin/microk8s enable ingress
/snap/bin/microk8s enable storage
/snap/bin/microk8s enable registry
while /snap/bin/microk8s kubectl get pods --namespace kube-system | grep '0/1'; do sleep 1; done

echo "[Epic №7] - Prepare .kube config"
mkdir -p /home/vagrant/.kube
/snap/bin/microk8s config > /home/vagrant/.kube/config
usermod -a -G microk8s vagrant
chown -f -R vagrant /home/vagrant/.kube
