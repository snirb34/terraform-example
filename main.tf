# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.82.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Data
data "azurerm_resource_group" "rg"{
    name = "${var.resource_group_name}"
}

# Resources
resource "azurerm_virtual_network" "vnet" {
  count = 3
  name                = "vnet${count.index}"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  address_space       = ["${var.address_space[count.index]}"]
}

resource "azurerm_subnet" "subnet" {
  count = 3
  name                 = "subnet${count.index}"
  virtual_network_name = "${azurerm_virtual_network.vnet[count.index].name}"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  address_prefixes     = ["${var.subnet_prefix[count.index]}"]
}

resource "azurerm_network_interface" "nic" {
  count               = 3
  name                = "nic${count.index}"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                                    = "ipconfig${count.index}"
    subnet_id                               = "${azurerm_subnet.subnet[count.index].id}"
    private_ip_address_allocation           = "Dynamic"
  }
}

resource "azurerm_virtual_network_peering" "a-to-b" {
  name                      = "vnet0_to_vnet1"
  resource_group_name       = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet[0].name}"
  remote_virtual_network_id = "${azurerm_virtual_network.vnet[1].id}"
}

resource "azurerm_virtual_network_peering" "b-to-a" {
  name                      = "vnet1_to_vnet0"
  resource_group_name       = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet[1].name}"
  remote_virtual_network_id = "${azurerm_virtual_network.vnet[0].id}"
}

resource "azurerm_virtual_network_peering" "a-to-c" {
  name                      = "vnet0_to_vnet2"
  resource_group_name       = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet[0].name}"
  remote_virtual_network_id = "${azurerm_virtual_network.vnet[2].id}"
}

resource "azurerm_virtual_network_peering" "c-to-a" {
  name                      = "vnet2_to_vnet0"
  resource_group_name       = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet[2].name}"
  remote_virtual_network_id = "${azurerm_virtual_network.vnet[0].id}"
}

resource "azurerm_virtual_machine" "main" {
  count = 3
  name                  = "vm${count.index}"
  location              = "${data.azurerm_resource_group.rg.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }
  storage_os_disk {
    name              = "osdisk${count.index}"
    create_option     = "FromImage"
  }
  os_profile {
    computer_name  = "hostname${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}