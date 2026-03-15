all:
  children:
    controlplane:
      hosts:
        k8s-cp-01:
          ansible_host: ${controlplane_ip}
          ansible_user: ${ssh_user}
          ansible_ssh_private_key_file: ${ssh_private_key_file}

    workers:
      hosts:
%{ for i, ip in worker_ips ~}
        k8s-wk-0${i + 1}:
          ansible_host: ${ip}
          ansible_user: ${ssh_user}
          ansible_ssh_private_key_file: ${ssh_private_key_file}
%{ endfor ~}

    k3s_cluster:
      children:
        controlplane:
        workers:
