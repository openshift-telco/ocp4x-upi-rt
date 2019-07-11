# ================MATCHBOX=====================

locals {
  kernel_args = [
    "console=tty0",
    "console=ttyS0,115200n8",
    "console=ttyS1,115200n8",
    "rd.neednet=1",
    "nameserver=${var.nameserver}",
    (var.provisioning_interface != "" ? "ip=${var.provisioning_interface}:dhcp" : " "),
    (var.baremetal_interface != "" ? "ip=${var.baremetal_interface}:dhcp" : " "),

    # "rd.break=initqueue"
    "coreos.inst=yes",

    "coreos.inst.image_url=${var.pxe_os_image_url}",
    "coreos.inst.install_dev=sda",
  ]

  pxe_kernel = "${var.pxe_kernel_url}"
  pxe_initrd = "${var.pxe_initrd_url}"

  master_public_ipv4 = "${var.master_public_ipv4}"
  bootstrap_public_ipv4 = "${var.bootstrap_public_ipv4}"
}

provider "matchbox" {
  endpoint    = "${var.matchbox_rpc_endpoint}"
  client_cert = "${file(var.matchbox_client_cert)}"
  client_key  = "${file(var.matchbox_client_key)}"
  ca          = "${file(var.matchbox_trusted_ca_cert)}"
}

resource "matchbox_profile" "default" {
  name = "${var.cluster_id}"
}

resource "matchbox_group" "default" {
  name    = "${var.cluster_id}"
  profile = "${matchbox_profile.default.name}"
}

resource "matchbox_profile" "master" {
  name   = "${var.cluster_id}-master"
  kernel = "${local.pxe_kernel}"

  initrd = [
    "${local.pxe_initrd}",
  ]

  args = flatten([
    "${local.kernel_args}",
    "coreos.inst.ignition_url=${var.matchbox_http_endpoint}/ignition?mac=${var.master_mac_address}",
  ])

  raw_ignition = "${file(var.master_ign_file)}"
}

resource "matchbox_group" "master" {
  name    = "${var.cluster_id}-master"
  profile = "${matchbox_profile.master.name}"

  selector = {
    mac = "${var.master_mac_address}"
  }
}


# ==============BOOTSTRAP=================

module "bootstrap" {
  source = "./bootstrap"

  pxe_kernel             = "${local.pxe_kernel}"
  pxe_initrd             = "${local.pxe_initrd}"
  pxe_kernel_args        = "${local.kernel_args}"
  matchbox_http_endpoint = "${var.matchbox_http_endpoint}"
  bootstrap_mac_address  = "${var.bootstrap_mac_address}"
  ignition_config_content = "${file(var.bootstrap_ign_file)}"

  bootstrap_ipmi_host     = "${var.bootstrap_ipmi_host}"
  bootstrap_ipmi_user     = "${var.bootstrap_ipmi_user}"
  bootstrap_ipmi_pass     = "${var.bootstrap_ipmi_pass}"

  cluster_id = "${var.cluster_id}"

}
