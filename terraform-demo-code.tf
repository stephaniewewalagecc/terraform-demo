terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" { 
  allow_reauth = false
}

variable "flavor_name" {
  description = "Flavor name for compue server"
  type = string
  default = "c1.c4r4"
}

variable "keyname" {
  description = "Keypair used for compute node"
  type = string
  default = "steph-key"
}

variable "image_name" {
  description = "OS image for compute node"
  type = string
  default = "ubuntu-18.04-x86_64"
}

data "openstack_compute_flavor_v2" "flavor" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "public_net" {
  name = "public-net"
}

data "openstack_images_image_v2" "server_image" {
  name = var.image_name
  most_recent = true
}

resource "openstack_networking_network_v2" "steph_network" {
  name = "steph_network"
}

resource "openstack_networking_subnet_v2" "steph_subnet" {
  network_id = openstack_networking_network_v2.steph_network.id
  name = "steph_subnet"
  cidr = "192.168.199.0/24"
}

resource "openstack_networking_router_v2" "steph_router" {
  name = "steph_router"
  external_network_id = data.openstack_networking_network_v2.public_net.id
}

resource "openstack_networking_router_interface_v2" "steph_interface" {
  router_id = openstack_networking_router_v2.steph_router.id
  subnet_id = openstack_networking_subnet_v2.steph_subnet.id
}

resource "openstack_networking_secgroup_v2" "steph_sg" {
  name = "steph_sg"
}

resource "openstack_networking_secgroup_rule_v2" "security_group_rule1" {
  security_group_id = openstack_networking_secgroup_v2.steph_sg.id
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 1
  port_range_max = 65535
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_port_v2" "steph_port" {
  name = "steph_port"
  network_id = openstack_networking_network_v2.steph_network.id
  security_group_ids = [ openstack_networking_secgroup_v2.steph_sg.id ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.steph_subnet.id
  }
}

resource "openstack_networking_floatingip_v2" "steph_fip" {
  pool = data.openstack_networking_network_v2.public_net.name
}

resource "openstack_networking_floatingip_associate_v2" "steph_fip_association" {
  floating_ip = openstack_networking_floatingip_v2.steph_fip.address
  port_id = openstack_networking_port_v2.steph_port.id
}

resource "openstack_compute_instance_v2" "qa_server" {
  name = "steph_server"
  key_pair = var.keyname

  flavor_id = data.openstack_compute_flavor_v2.flavor.id

  network {
    port = openstack_networking_port_v2.steph_port.id
  }

   block_device {
     delete_on_termination = true 
     source_type = "image"
     volume_size = 10
     destination_type = "volume"
     uuid = data.openstack_images_image_v2.server_image.id
  }

  user_data = templatefile("./cloud-init.tpl", {domain="example",email="me@example.com"})
}

output "floating_ip" {
  value = openstack_networking_floatingip_v2.steph_fip.address
}
