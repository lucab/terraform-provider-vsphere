variable "plan" {
  default = "c1.xlarge.x86"
}

variable "esxi_version" {
  default = "6.5"
}

variable "facility" {
  default = "ams1"
}

variable "ovftool_url" {
  description = "URL from which to download ovftool"
}
variable "vcsa_iso_url" {
  description = "URL from which to download VCSA ISO"
}

locals {
  esxi_ssl_cert_thumbprint_path = "ssl_cert_thumbprint.txt"
}

provider "packet" {
}

resource "packet_project" "test" {
  name = "Terraform Acc Test vSphere"
}

data "packet_operating_system" "helper" {
  name             = "CentOS"
  distro           = "centos"
  version          = "7"
  provisionable_on = "t1.small.x86"
}

data "local_file" "esxi_thumbprint" {
  filename = "${path.module}/${local.esxi_ssl_cert_thumbprint_path}"
}

data "template_file" "vcsa" {
  template = "${file("vcsa-template.json")}"
  vars = {
    esxi_host     = "${packet_device.esxi.network.0.address}"
    esxi_username = "root"
    esxi_password = "${packet_device.esxi.root_password}"
    esxi_ssl_cert_thumbprint = "${data.local_file.esxi_thumbprint.content}"
    ipv4_address = "" # TODO: Compute next IP after packet_device.esxi.network.address
    ipv4_prefix = "" # TODO: Compute from packet_device.esxi.network.cidr
    ipv4_gateway = "${packet_device.esxi.network.0.gateway}"
    network_name = "${packet_device.esxi.network.0.address}"
    os_password = "" # TODO: generate
    sso_password = "" # TODO: generate
  }
}

resource "local_file" "vcsa" {
  content  = "${data.template_file.vcsa.rendered}"
  filename = "${path.module}/template.json"
}

resource "packet_device" "helper" {
  hostname         = "tf-acc-vmware-helper"
  plan             = "t1.small.x86"
  facilities       = ["${var.facility}"]
  operating_system = "${data.packet_operating_system.helper.id}"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.test.id}"

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = "${self.network.0.address}"
      user     = "root"
      password = "${self.root_password}"
    }

    inline = [
<<SCRIPT
OVFTOOL_URL=${var.ovftool_url}
VCSA_ISO_URL=${var.vcsa_iso_url}
VCSA_TPL_PATH=${local_file.vcsa.filename}
./install-vcsa.sh
SCRIPT
    ]
  }
}


data "packet_operating_system" "esxi" {
  name             = "VMware ESXi"
  distro           = "vmware"
  version          = "${var.esxi_version}"
  provisionable_on = "${var.plan}"
}

resource "packet_device" "esxi" {
  hostname         = "tf-acc-vmware-esxi"
  plan             = "${var.plan}"
  facilities       = ["${var.facility}"]
  operating_system = "${data.packet_operating_system.esxi.id}"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.test.id}"

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = "${self.network.0.address}"
      user     = "root"
      password = "${self.root_password}"
    }

    inline = [
      "mktmp -d", # TODO
      "openssl x509 -in /etc/vmware/ssl/rui.crt -fingerprint -sha1 -noout > TODO/tmp"
    ]
  }

  provisioner "file" {
    # TODO: scp from tmp to local.esxi_ssl_cert_thumbprint_path
  }
}
