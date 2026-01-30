# Azure Subscription ID - WYMAGANE!
# Pobierz za pomocą: az account show --query id -o tsv
subscription_id = "bfb43e7e-baea-4297-9d45-2fb7d6b34af1"
admin_ids = ["deb6d050-8dbb-45e2-978d-68b8bfee4e72"]
# Twój publiczny adres IP dla dostępu SSH
# Pobierz za pomocą: (Invoke-WebRequest -Uri "https://api.ipify.org").Content
my_ip_address = "109.95.113.105"
ssh_public_key_path = "C:\\Users\\rmars\\.ssh\\id_rsa.pub" # dla linux "~/.ssh/id_rsa.pub"
# Opcjonalne - możesz nadpisać domyślne wartości
# location            = "westeurope"
# resource_group_name = "rg-meetup-aks"
# environment         = "dev"
# vm_admin_username   = "azureuser"
# vm_size             = "Standard_B2s"

# Ścieżka do klucza SSH - upewnij się, że plik istnieje
# ssh_public_key_path = "~/.ssh/id_rsa.pub"
