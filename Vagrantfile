# ============================================================================
# Vagrantfile: VirtualBox VM for Deployment Target
# ============================================================================
# Creates an Ubuntu 22.04 VM in VirtualBox that serves as the deployment target.
# The Ansible playbook deploys the Docker containers to this VM.
#
# Usage:
#   vagrant up          # Create and start VM
#   vagrant ssh         # SSH into VM
#   vagrant halt        # Stop VM
#   vagrant destroy     # Delete VM
# ============================================================================

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "buyer-portal-vm"

  # Private network for Ansible connectivity
  config.vm.network "private_network", ip: "192.168.56.10"

  # Forward ports so you can access services from Windows host
  config.vm.network "forwarded_port", guest: 5000, host: 5000   # App
  config.vm.network "forwarded_port", guest: 9090, host: 9090   # Prometheus
  config.vm.network "forwarded_port", guest: 3001, host: 3001   # Grafana

  config.vm.provider "virtualbox" do |vb|
    vb.name = "buyer-portal-devops"
    vb.memory = "2048"
    vb.cpus = 2
  end

  # Basic provisioning - install Docker so Ansible has less work
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -qq
    apt-get install -y -qq python3 python3-pip
    echo "VM is ready for Ansible deployment!"
  SHELL
end
