How to run K3s locally and create a multi-node cluster using VMs
================================================================

A) SETUP VMs ON HOST MACHINE: they will be the k3s nodes

B) SETUP K3S ON THE VMs: One Control Plane and two Worker nodes

------------------------------------------------------------------------------------------------------------

(A) Setup VMs on host machine

To start three VMs on an ARM-based macOS host using QEMU from a Bash shell, you can create and launch Ubuntu VMs for a K3s cluster. Below are the steps to set up and start the VMs using QEMU on the command line. This assumes you have QEMU installed and an Ubuntu image ready.

**Prerequisites**:
- QEMU installed (e.g., via `brew install qemu`).
- Ubuntu Server ARM64 ISO downloaded (e.g., `ubuntu-22.04.3-live-server-arm64.iso` from Ubuntu’s website).
- Basic network setup (bridge or NAT for VM communication).

**Steps**:

1. **Prepare Disk Images**:
   Create three QCOW2 disk images for the VMs (one control plane, two workers):
   ```bash
   qemu-img create -f qcow2 vm1-disk.qcow2 20G
   qemu-img create -f qcow2 vm2-disk.qcow2 20G
   qemu-img create -f qcow2 vm3-disk.qcow2 20G
   ```

2. **Create Cloud-Init Config**:
   Create a `cloud-init.yaml` for each VM to automate Ubuntu setup (e.g., SSH keys, user). Example for VM1 (adjust for VM2, VM3 with different hostnames/IPs):
   ```yaml
   #cloud-config
   hostname: k3s-control
   users:
     - name: ubuntu
       sudo: ALL=(ALL) NOPASSWD:ALL
       ssh-authorized-keys:
         - <your-ssh-public-key> # Replace with your SSH key
   chpasswd:
     list: |
       ubuntu:ubuntu
     expire: false
   write_files:
     - path: /etc/netplan/00-installer-config.yaml
       content: |
         network:
           ethernets:
             enp0s1:
               dhcp4: no
               addresses: [192.168.1.101/24]
               gateway4: 192.168.1.1
               nameservers:
                 addresses: [8.8.8.8, 8.8.4.4]
           version: 2
   runcmd:
     - netplan apply
   ```
   Save as `vm1-cloud-init.yaml`, `vm2-cloud-init.yaml` (IP: 192.168.1.102, hostname: k3s-worker1), `vm3-cloud-init.yaml` (IP: 192.168.1.103, hostname: k3s-worker2).

3. **Convert Cloud-Init to ISO**:
   Create a Cloud-Init ISO for each VM:
   ```bash
   mkisofs -output vm1-cidata.iso -volid cidata -joliet -rock vm1-cloud-init.yaml
   mkisofs -output vm2-cidata.iso -volid cidata -joliet -rock vm2-cloud-init.yaml
   mkisofs -output vm3-cidata.iso -volid cidata -joliet -rock vm3-cloud-init.yaml
   ```

4. **Start VMs with QEMU**:
   Launch each VM with QEMU, assigning 2 CPUs, 2GB RAM, and a bridged or NAT network. Example for VM1 (control plane):
   ```bash
   qemu-system-aarch64 \
     -machine virt,accel=hvf \
     -m 2048 \
     -cpu host \
     -smp 2 \
     -drive file=vm1-disk.qcow2,format=qcow2 \
     -cdrom ubuntu-22.04.3-live-server-arm64.iso \
     -drive file=vm1-cidata.iso,format=raw \
     -netdev user,id=net0,hostfwd=tcp::2221-:22 \
     -device virtio-net-pci,netdev=net0 \
     -nographic
   ```
   For VM2 and VM3, adjust the disk (`vm2-disk.qcow2`, `vm3-disk.qcow2`), Cloud-Init ISO (`vm2-cidata.iso`, `vm3-cidata.iso`), and SSH port forwarding (e.g., `:2222`, `:2223`).

5. **Automate with Bash Script**:
   Create a Bash script (`start-vms.sh`) to launch all VMs:
   ```bash
   #!/bin/bash
   # VM1: Control Plane
   qemu-system-aarch64 \
     -machine virt,accel=hvf \
     -m 2048 \
     -cpu cortex-a72 \
     -smp 2 \
     -drive file=vm1-disk.qcow2,format=qcow2 \
     -cdrom ubuntu-22.04.3-live-server-arm64.iso \
     -drive file=vm1-cidata.iso,format=raw \
     -netdev user,id=net0,hostfwd=tcp::2221-:22 \
     -device virtio-net-pci,netdev=net0 \
     -nographic &

   # VM2: Worker 1
   qemu-system-aarch64 \
     -machine virt,accel=hvf \
     -m 2048 \
     -cpu cortex-a72 \
     -smp 2 \
     -drive file=vm2-disk.qcow2,format=qcow2 \
     -cdrom ubuntu-22.04.3-live-server-arm64.iso \
     -drive file=vm2-cidata.iso,format=raw \
     -netdev user,id=net1,hostfwd=tcp::2222-:22 \
     -device virtio-net-pci,netdev=net1 \
     -nographic &

   # VM3: Worker 2
   qemu-system-aarch64 \
     -machine virt,accel=hvf \
     -m 2048 \
     -cpu cortex-a72 \
     -smp 2 \
     -drive file=vm3-disk.qcow2,format=qcow2 \
     -cdrom ubuntu-22.04.3-live-server-arm64.iso \
     -drive file=vm3-cidata.iso,format=raw \
     -netdev user,id=net2,hostfwd=tcp::2223-:22 \
     -device virtio-net-pci,netdev=net2 \
     -nographic &
   ```
   Run with:
   ```bash
   chmod +x start-vms.sh
   ./start-vms.sh
   ```

6. **Access VMs**:
   - SSH into VMs (e.g., `ssh -p 2221 ubuntu@localhost` for VM1).
   - Complete Ubuntu installation if needed (Cloud-Init automates most setup).
   - Follow previous K3s setup steps (install K3s, join workers).

**Notes**:
- **Networking**: The example uses QEMU’s user networking with port forwarding for simplicity. For VM-to-VM communication, set up a bridge network (e.g., `bridge0` on macOS) and use `-netdev bridge` instead.
- **Performance**: Ensure `hvf` (Hypervisor Framework) is enabled for better performance on ARM macOS.
- **ISO**: The Ubuntu ISO is used for initial setup. After installation, remove `-cdrom` from QEMU commands for subsequent boots.
- **Automation**: Cloud-Init simplifies VM configuration. Adjust IPs and hostnames as needed.
- **Shutdown**: Stop VMs with `killall qemu-system-aarch64` or from within each VM.

This sets up three VMs for a local K3s cluster on your ARM macOS system.

------------------------------------------------------------------------------------------------------------

(B) Steps to Set Up K3s Locally with Multiple VMs
-------------------------------------------------

1. **Prerequisites**:
   - Install a VM tool (e.g., VirtualBox, VMware, or Multipass).
   - Ensure each VM has Linux (e.g., Ubuntu), 2GB+ RAM, 2+ CPUs, and network connectivity.
   - Install `curl` on each VM.

2. **Create VMs**:
   - Spin up 3 VMs (e.g., one for the control plane, two for worker nodes) using your VM tool. Assign IPs (e.g., 192.168.1.101, 102, 103).

3. **Install K3s on Control Plane Node**:
   - On the first VM (e.g., 192.168.1.101), run:
     ```
     curl -sfL https://get.k3s.io | sh -
     ```
   - Get the node token for joining workers:
     ```
     sudo cat /var/lib/rancher/k3s/server/node-token
     ```

4. **Join Worker Nodes**:
   - On each worker VM (e.g., 192.168.1.102, 103), run:
     ```
     curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.101:6443 K3S_TOKEN=<node-token> sh -
     ```
     Replace `<node-token>` with the token from step 3.

5. **Verify Cluster**:
   - On the control plane VM, run:
     ```
     sudo k3s kubectl get nodes
     ```
     Confirm all 3 nodes (1 control plane, 2 workers) are listed with `Ready` status.

6. **Deploy Your Application**:
   - Use the `k8s-config.yaml` from the previous response (Python script, Postgres, Grafana):

===snip===
---
# Namespace for organization
apiVersion: v1
kind: Namespace
metadata:
  name: app-namespace
---
# Secret for Postgres credentials
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: app-namespace
type: Opaque
data:
  postgres-user: cG9zdGdyZXM= # base64 encoded "postgres"
  postgres-password: cGFzc3dvcmQ= # base64 encoded "password"
---
# Deployment for Python script (5 replicas)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
  namespace: app-namespace
spec:
  replicas: 5
  selector:
    matchLabels:
      app: python-app
  template:
    metadata:
      labels:
        app: python-app
    spec:
      containers:
      - name: python-container
        image: your-registry/your-image-name:tag # Replace with your image
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
---
# Service for Python app (if it exposes a port)
apiVersion: v1
kind: Service
metadata:
  name: python-service
  namespace: app-namespace
spec:
  selector:
    app: python-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80 # Adjust if your app uses a specific port
  type: ClusterIP
---
# PersistentVolumeClaim for Postgres
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: app-namespace
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard # Adjust based on cloud provider
---
# StatefulSet for Postgres
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: app-namespace
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        - name: POSTGRES_DB
          value: myapp
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          limits:
            cpu: "1"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
# Service for Postgres
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: app-namespace
spec:
  selector:
    app: postgres
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
  type: ClusterIP
---
# Deployment for Grafana
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: app-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:9.5.2
        ports:
        - containerPort: 3000
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
---
# Service for Grafana
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: app-namespace
spec:
  selector:
    app: grafana
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: LoadBalancer # Exposes Grafana externally
---
# Optional: Ingress for external access (if supported)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: app-namespace
  annotations:
    kubernetes.io/ingress.class: nginx # Adjust based on provider
spec:
  rules:
  - host: grafana.your-domain.com # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana-service
            port:
              number: 3000
===snap===

   - Copy the YAML to the control plane VM.
   - Apply with:
     ```
     sudo k3s kubectl apply -f k8s-config.yaml
     ```

7. **Access Services**:
   - For Grafana’s LoadBalancer, check the external IP:
     ```
     sudo k3s kubectl -n app-namespace get svc grafana-service
     ```
   - If no external IP is assigned (common in local setups), use `k3s kubectl port-forward` to access Grafana (e.g., `port-forward svc/grafana-service 3000:3000 -n app-namespace`).

8. **Optional: Local Registry**:
   - If you don’t want to push your Python image to a remote registry, set up a local Docker registry on one VM (e.g., `docker run -d -p 5000:5000 registry:2`).
   - Push your image to `localhost:5000/your-image-name:tag` and update the YAML to use this.

**Notes**:
- **Storage**: For Postgres, ensure a local storage class is configured (K3s provides a default `local-path` class).
- **Networking**: Ensure VMs can communicate (same network/subnet). For Multipass, use `multipass list` to check IPs.
- **Resource Needs**: Each VM needs ~2GB RAM and 2 CPUs for smooth operation.
- **Cleanup**: Stop VMs or run `k3s-uninstall.sh` on each VM to remove K3s.

This setup mimics a production-like multi-node cluster locally, ideal for testing your application before deploying to a cloud provider.