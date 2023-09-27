resource "azurerm_resource_group" "rg" {
  location = "eastus"
  name     = "cartsprod"
}

resource "azurerm_container_registry" "carts" {
  name                = "cartsprod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}


resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = "cart-aks"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "cart-aks-dns"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}

resource "azurerm_role_assignment" "cart" {
  principal_id                     = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.carts.id
  skip_service_principal_aad_check = true
}