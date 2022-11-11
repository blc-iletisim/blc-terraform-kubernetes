terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.48.0"
    }
    github = {
      source  = "integrations/github"
      version = "5.7.0"
    }
  }
}

#vars.json file
locals {
  #local_data = jsondecode(file("${path.module}/var.json"))
  local_data = jsondecode(file("/root/blc/blcs/blcs/var.json"))
}



provider "openstack" {
    user_name   = local.local_data.user_name
    tenant_name = local.local_data.tenant_name
    password    = local.local_data.password
    auth_url    = "http://10.150.1.251:5000"
    region      = "RegionOne"
    #domain_name = "Default"

}

resource "openstack_networking_port_v2" "port_1" {
    name = "port_1"
    admin_state_up = "true"
    network_id = "f0ad3870-01d3-41e1-b6dd-dccf6f424de4"
}

resource "openstack_compute_instance_v2" "kubernetes" {
    name            = "kubernetes"
    image_id        = local.local_data.image_id
    flavor_id       = local.local_data.flavor_id
    key_pair        = local.local_data.key_pair
    network {
      name = "Internal"
    }
}

resource "openstack_networking_floatingip_v2" "admin" {
  pool = "External"
}

output "pool" {
  value       = openstack_networking_floatingip_v2.admin
}


resource "openstack_compute_floatingip_associate_v2" "admin" {
  floating_ip = "${openstack_networking_floatingip_v2.admin.address}"
  instance_id = "${openstack_compute_instance_v2.kubernetes.id}"
/*
  connection {
        type = "ssh"
        agent = false
        user = "ubuntu"
        private_key = "${file("/home/ubuntu/deploy-openstack/ssh-terra/blc-cloud.pem")}"
        host = "${openstack_networking_floatingip_v2.admin.address}"
        //host = "${openstack_networking_port_v2.port_1.id}"
    }
    
    provisioner "remote-exec" {
        inline = [
            "sudo apt update -y",
            "sudo apt install apache2 -y",
        ]
    }
*/
}


resource "null_resource" "remote-exec" {
  provisioner "remote-exec" {
    connection {
      type ="ssh"
      agent = false
      user = "ubuntu"
      private_key = "${file("${path.module}/blc-cloud.pem")}"
      host = "${openstack_networking_floatingip_v2.admin.address}"
    }
    inline = [
      "git clone https://github.com/blc-iletisim/blc-kubernetes-shell.git",
      "cd blc-kubernetes-shell",
      "sudo ./kubernetes.sh"
    ]
  }
}



