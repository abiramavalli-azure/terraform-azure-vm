provider "azurerm" {
  features {}
 subscription_id = "6f3cc6e5-4e69-4298-ab8c-3d4864458ffe"
}
resource "azurerm_resource_group" "rg" {
  name     = "demo-rg"
  location = "Canada Central"
}


resource "azurerm_network_security_group" "nsg" {
  name                = "rg-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "rg-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "subnet1"
    address_prefixes = ["10.0.1.0/24"]
  }

  subnet {
    name             = "subnet2"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.nsg.id
  }
  tags = {
    environment = "Production"
  }
}
data "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}


resource "azurerm_storage_account" "storage" {
  name                     = "demostorageaccount8899"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}
resource "azurerm_network_interface" "nic" {
  name                = "demo-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "demo-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_E2s_v3"



  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "demovm"
    admin_username = "abiramavalliv"
    admin_password = "Abi@hanshu88"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}