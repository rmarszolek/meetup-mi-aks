
Jesteś specjalistą od Azure i AKS, piszesz kod w Terraformie. Wygeneruj kompletną infrastrukturę, którą będę uruchamiał lokalnie (po az login).

Wymagania ogólne:

Stwórz plik provider.tf z providerem azurerm. ID subskrypcji ma być przekazywane jako zmienna.

Stwórz plik variables.tf. Zdefiniuj zmienną my_ipaddress (domyślnie moje publiczne IP), która będzie używana do reguł firewall.

Architektura Sieciowa (Hub & Spoke):

VNet Hub: Zawiera maszynę wirtualną (VM) Ubuntu.

VNet Spoke: Zawiera 3 podsieci:

snet-aks (dla Control Plane/System pool AKS).

snet-aks-nodes (dla User Node pools i Podów - duża adresacja).

snet-private-endpoints (dla Storage, Key Vault, SQL).

Ustaw VNet Peering pomiędzy Hub i Spoke.

Bezpieczeństwo Sieciowe (NSG):

NSG dla Hub VM: Zezwól na SSH (port 22) tylko ze źródła var.my_ipaddress do prywatnego IP maszyny.

NSG dla Private Endpoints (snet-private-endpoints):

Usuń domyślną regułę AllowVnetInbound (zablokuj ruch wewnątrz VNet).

Zezwól na HTTPS/HTTP ze źródła var.my_ipaddress oraz z adresu VM w Hub.

Zezwól na SMB (port 445) tylko z VM w Hub.

Zezwól na dostęp do SQL z VM w Hub oraz z podsieci snet-aks-nodes (dla podów).

Tożsamości (Managed Identities):
Utwórz 3 User Assigned Identities:

Dla klastra AKS (id-aks-cluster).

Dla Kubelet (id-aks-kubelet).

Dla Workload Identity.
Ważne: Nadaj tożsamości klastra (id-aks-cluster) uprawnienie "Managed Identity Operator" na zasobie tożsamości Kubelet (id-aks-kubelet), aby uniknąć błędu uprawnień.

Zasoby PaaS (Private Link & Security):
Każdy z poniższych zasobów ma mieć:

Dostęp publiczny ograniczony tylko do var.my_ipaddress (do zarządzania).

Private Endpoint w podsieci snet-private-endpoints.

Private DNS Zone podlinkowaną do obu sieci (Hub i Spoke).

Nie używaj Service Endpoints, tylko Private Endpoints.

Storage Account:

Replikacja: LRS (nie LZR).

Azure Files (SMB).

Network Rules: Deny all, allow var.my_ipaddress. Private Endpoint obsługuje DNS automatycznie (bez ręcznych rekordów A).

Key Vault:

Model uprawnień: RBAC (nie Access Policies).

Retencja: Soft Delete 7 dni, bez Purge Protection (do celów testowych - kasowanie i reużywanie nazwy).

Azure SQL Database:

Model: Serverless (najtańszy, auto-pause, vCore).

Autoryzacja: Azure AD Auth + Managed Identity Support.

Azure Kubernetes Service (AKS):

API Server: Dostęp publiczny, ale ograniczony przez authorized_ip_ranges tylko do var.my_ipaddress.

Sieć (CNI):

Plugin: azure (Azure CNI).

Mode: VNet (pody i nody pobierają IP z podsieci, nie używaj trybu Overlay).

Network Policy: azure (Azure Network Policy Manager).

Node Pools:

System Pool: 1-3 nody, seria B (np. B2s), w podsieci snet-aks.

Worker Pool: 1-3 nody, seria B (np. B2ms), w podsieci snet-aks-nodes.

Upgrades: Użyj parametru automatic_channel_upgrade = "patch".

Wygeneruj kompletny kod Terraform podzielony na pliki.