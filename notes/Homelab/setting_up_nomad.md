---
date: 2023-02-07T01:17
title: HashiCorp Nomad Setup
---

I like HashiCorp's products, and wanted to try running a cluster with some of
them in order to learn more about and build stuff using it. The first one on the
list is Nomad, which this post will cover how to setup it in a single Debian
node and create a cluster. Most of the commands shown here are aggregated and
adapted from the referenced HashiCorp documentation pages.

# Install Nomad

```sh 
# Add HashiCorp's repository
sudo apt-get update && sudo apt-get install wget gpg coreutils wget lsb-release
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install nomad
sudo apt-get update && sudo apt-get install nomad

# Nomad directories and user setup
sudo mkdir -p /opt/nomad
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
sudo chown -R nomad /opt/nomad

# Install Docker (optional if you do not pretend to run containers or use podman)
sudo apt-get install docker.io
sudo usermod -G docker -a nomad
```

For post-installation steps, such as setting up CNI plugins or Vagrant, refer to
the [official documentation](https://developer.hashicorp.com/nomad/tutorials/get-started/get-started-install#post-installation-steps).

# Setup the Nomad Agent Unit


Add the following content into `/etc/systemd/system/nomad.service`:

```toml
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]

# Nomad server should be run as the nomad user. Nomad clients
# should be run as root
User=nomad
Group=nomad

ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
```

Enable and start the Nomad systemd service by running:

```sh
sudo systemctl enable nomad
sudo systemctl start nomad
```

# Nomad Config

Add the following content into `/etc/nomad.d/nomad.hcl`:

```hcl
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

datacenter = "dc1"

data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"

server {
  enabled = true
}

client {
  enabled = true
}
```

# Running a Job

Note that this job requires docker to be installed in the host.

Add the following content in a `first-job.nomad` file:

```hcl 
job "rabbit" {
  datacenters = ["dc1"]

  group "rabbitmq" {
    network {
      port "rabbit" {
        to = 5672
      }

      port "management" {
        to = 15672
      }
    }

    task "rabbit" {
      driver = "docker"

      config {
        image = "rabbitmq:3-management"
        ports = ["rabbit", "management"]
        auth_soft_fail = true
      }

      resources {
        cpu = 500
        memory = 512
      }
    }
  }
}
```

Then do a dry run of the deployment by running `nomad job plan first-job.nomad`.

If everything went well, Nomad will tell you it can create the deployment
succesfully and show you the command to start the process. You can then run this
command, wait until it finishes and check the results the `Jobs` section inside
[Nomad's web interface](127.0.0.1:4646).

# Clustering with Consul

In order to create a cluster with our own nodes, we will leverage the existing
Nomad + Consul integration for service discovery. Add the following section to
every Nomad node you want to connect to the cluster:

```hcl
# Inside the server block, add bootstrap_expect with the number of nodes that
# you will run in your cluster
server {
  bootstrap_expect = 3
}

consul {
  # The address to the Consul Agent
  address = "consul-ip:5000"

  # The service name to register the server and client with Consul
  server_service_name = "nomad"
  client_service_name = "nomad-client"

  # Enables automatically registering the services
  auto_advertise = true

  # Enabling the server and client to bootstrap using consul
  server_auto_join = true
  client_auto_join = true
}
```

# Wrapping up

Nomad is an awesome scheduler and orchestrator, and it is being pretty
refreshing using its simple API in order to get started learning about
orchestrators. I hope this post helps some curious readers and my future self
when setting Nomad up.

In order to continue learning about Nomad, check [HashiCorp's
docs](https://developer.hashicorp.com/nomad/docs).

# Resources
- [Install Nomad](https://developer.hashicorp.com/nomad/tutorials/get-started/get-started-install)
- [Nomad Deployment Guide](https://developer.hashicorp.com/nomad/tutorials/enterprise/production-deployment-guide-vm-with-consul)
- [Start Nomad and Run Your First Job](https://developer.hashicorp.com/nomad/tutorials/get-started/get-started-run)
- [Connect Nodes into a Cluster](https://developer.hashicorp.com/nomad/tutorials/manage-clusters/clustering)

