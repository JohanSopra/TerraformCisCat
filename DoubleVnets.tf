provider "azurerm" {
  version = "1.44.0"
}

##################################################################################
# DATA
##################################################################################
data "azurerm_resource_group" "group_res" {
  name = "HubSpokesStagiaire"
}

##################################################################################
# RESOURCES
##################################################################################
resource "azurerm_virtual_network" "VN_doubleVnets" {
  name                = "VN_doubleVnets"
  location            = data.azurerm_resource_group.group_res.location
  resource_group_name = data.azurerm_resource_group.group_res.name
  address_space       = ["10.0.0.0/8"]

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_subnet" "hub_subnet" {
  name                 = "hub_subnet"
  resource_group_name  = data.azurerm_resource_group.group_res.name
  virtual_network_name = azurerm_virtual_network.VN_doubleVnets.name
  address_prefix       = "10.1.0.0/16"
}

resource "azurerm_subnet" "spoke_subnet" {
  name                 = "spoke_subnet"
  resource_group_name  = data.azurerm_resource_group.group_res.name
  virtual_network_name = azurerm_virtual_network.VN_doubleVnets.name
  address_prefix       = "10.2.0.0/16"
}

resource "azurerm_subnet" "spoke_subnetWin" {
  name                 = "spoke_subnetWin"
  resource_group_name  = data.azurerm_resource_group.group_res.name
  virtual_network_name = azurerm_virtual_network.VN_doubleVnets.name
  address_prefix       = "10.3.0.0/16"
}

resource "azurerm_network_security_group" "nsg_hub" {
  name                = "nsg_hub"
  location            = "northeurope"
  resource_group_name = data.azurerm_resource_group.group_res.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_security_group" "nsg_spoke" {
  name                = "nsg_spoke"
  location            = "northeurope"
  resource_group_name = data.azurerm_resource_group.group_res.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.1.0.4"
    destination_address_prefix = "*"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_security_group" "nsg_spokeWin" {
  name                = "nsg_spokeWin"
  location            = "northeurope"
  resource_group_name = data.azurerm_resource_group.group_res.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.1.0.5"
    destination_address_prefix = "*"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_hub" {
  subnet_id                 = azurerm_subnet.hub_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_hub.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_spoke" {
  subnet_id                 = azurerm_subnet.spoke_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_spoke.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_spokeWin" {
  subnet_id                 = azurerm_subnet.spoke_subnetWin.id
  network_security_group_id = azurerm_network_security_group.nsg_spokeWin.id
}

resource "azurerm_public_ip" "hubVM-pip" {
  name                = "hubVM-pip"
  location            = "northeurope"
  resource_group_name = data.azurerm_resource_group.group_res.name
  allocation_method   = "Static"

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_public_ip" "hubWinVM-pip" {
  name                = "hubWinVM-pip"
  location            = "northeurope"
  resource_group_name = data.azurerm_resource_group.group_res.name
  allocation_method   = "Static"

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}


resource "azurerm_network_interface" "hub_nic" {
  name                      = "hub_nic"
  resource_group_name       = data.azurerm_resource_group.group_res.name
  location                  = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_hub_nic"
    subnet_id                     = azurerm_subnet.hub_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hubVM-pip.id
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "hubWinVM_nic" {
  name                      = "hubWinVM_nic"
  resource_group_name       = data.azurerm_resource_group.group_res.name
  location                  = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_hubWinVM_nic"
    subnet_id                     = azurerm_subnet.hub_subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.hubWinVM-pip.id
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "spoke_nic" {
  name                = "spoke_nic"
  resource_group_name = data.azurerm_resource_group.group_res.name
  location            = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_subnet_nic"
    subnet_id                     = azurerm_subnet.spoke_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "spoke_nic2" {
  name                = "spoke_nic2"
  resource_group_name = data.azurerm_resource_group.group_res.name
  location            = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_subnet_nic2"
    subnet_id                     = azurerm_subnet.spoke_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "spoke_nic3" {
  name                = "spoke_nic3"
  resource_group_name = data.azurerm_resource_group.group_res.name
  location            = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_subnet_nic3"
    subnet_id                     = azurerm_subnet.spoke_subnetWin.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "spoke_nic4" {
  name                = "spoke_nic4"
  resource_group_name = data.azurerm_resource_group.group_res.name
  location            = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_subnet_nic4"
    subnet_id                     = azurerm_subnet.spoke_subnetWin.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "spoke_nic5" {
  name                = "spoke_nic5"
  resource_group_name = data.azurerm_resource_group.group_res.name
  location            = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_subnet_nic5"
    subnet_id                     = azurerm_subnet.spoke_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_network_interface" "spoke_nic6" {
  name                = "spoke_nic6"
  resource_group_name = data.azurerm_resource_group.group_res.name
  location            = data.azurerm_resource_group.group_res.location

  ip_configuration {
    name                          = "IPconfig_subnet_nic6"
    subnet_id                     = azurerm_subnet.spoke_subnetWin.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}


resource "azurerm_virtual_machine" "hubVM" {
  name                  = "hubVM"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.hub_nic.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hubVM_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hubVM"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
      disable_password_authentication=false
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "hubWinVM" {
  name                  = "hubWinVM"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.hubWinVM_nic.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2016-Datacenter"
  version   = "latest"
}

  storage_os_disk {
    name              = "hubWinVM_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hubWinVM"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
  }

  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "spokeVM" {
  name                  = "spokeVM"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.spoke_nic.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

   storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "spokeVM_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokeVM"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
      disable_password_authentication=false
  }


  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "spokeVM2" {
  name                  = "spokeVM2"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.spoke_nic2.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

   storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1"
    version   = "8.1.2020020415"
  }

  storage_os_disk {
    name              = "spokeVM_osdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokeVM2"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
      disable_password_authentication=false
  }


  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "spokeVM3" {
  name                  = "spokeVM3"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.spoke_nic3.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

   storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h2-ent-g2"
    version   = "18363.657.2002091847"
  }

  storage_os_disk {
    name              = "spokeVM_osdisk3"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokeVM3"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
  }


  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "spokeVM4" {
  name                  = "spokeVM4"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.spoke_nic4.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

   storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h2-ent-g2"
    version   = "18363.657.2002091847"
  }

  storage_os_disk {
    name              = "spokeVM_osdisk4"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokeVM4"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
  }


  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "spokeVM5" {
  name                  = "spokeVM5"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.spoke_nic5.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

   storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1"
    version   = "8.1.2020020415"
  }

  storage_os_disk {
    name              = "spokeVM_osdisk5"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokeVM5"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication=false
  }


  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}

resource "azurerm_virtual_machine" "spokeVM6" {
  name                  = "spokeVM6"
  location              = data.azurerm_resource_group.group_res.location
  resource_group_name   = data.azurerm_resource_group.group_res.name
  network_interface_ids = [azurerm_network_interface.spoke_nic6.id]
  vm_size               = var.vmsize


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

   storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "rs5-enterprise"
    version   = "17763.973.2001110547"
  }

  storage_os_disk {
    name              = "spokeVM_osdisk6"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokeVM6"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_windows_config {
  }


  tags = {
    owner = "johan.boury@soprasteria.com"
  }
}
##################################################################################
# OUTPUT
##################################################################################
