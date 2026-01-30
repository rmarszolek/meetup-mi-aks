# Dokumentacja Techniczna Projektu: Infrastruktura dla AKS w Modelu Hub & Spoke

**Cel projektu:** Stworzenie kompletnej, bezpiecznej i gotowej do użycia infrastruktury na platformie Microsoft Azure przy użyciu Terraform. Architektura jest zoptymalizowana pod kątem hostowania klastra Azure Kubernetes Service (AKS) i powiązanych usług PaaS w bezpiecznej topologii sieciowej Hub & Spoke.

---

## 1. Opis Architektury

Infrastruktura opiera się na sprawdzonym wzorcu architektonicznym Hub & Spoke, który centralizuje wspólne usługi i izoluje środowiska robocze.

### 1.1. Topologia Sieci (Hub & Spoke)

- **VNet Hub (`vnet-hub`)**
  - **Adresacja:** `10.0.0.0/16`
  - **Cel:** Centralny punkt łączności i zarządzania.
  - **Podsieci:**
    - `snet-vm` (`10.0.1.0/24`): Zawiera maszynę wirtualną typu "jumpbox" (Ubuntu), która służy do bezpiecznego dostępu administracyjnego do pozostałych zasobów.

- **VNet Spoke (`vnet-spoke`)**
  - **Adresacja:** `10.1.0.0/16`
  - **Cel:** Hostowanie klastra AKS oraz powiązanych usług.
  - **Podsieci:**
    - `snet-aks` (`10.1.0.0/20`): Dedykowana dla puli systemowej (System Node Pool) klastra AKS.
    - `snet-aks-nodes` (`10.1.16.0/20`): Duża przestrzeń adresowa dla pul roboczych (Worker Node Pools) oraz podów aplikacji. Pody otrzymują adresy IP bezpośrednio z tej podsieci dzięki Azure CNI.
    - `snet-private-endpoints` (`10.1.32.0/24`): Izolowana podsieć wyłącznie dla prywatnych punktów końcowych (Private Endpoints), zapewniająca bezpieczną komunikację z usługami PaaS.

- **VNet Peering**
  - Skonfigurowano dwukierunkowy peering między VNet Hub i VNet Spoke. Umożliwia to płynną komunikację, np. dostęp z maszyny VM w Hubie do prywatnych punktów końcowych w Spoke.

### 1.2. Bezpieczeństwo Sieci (NSG)

- **NSG dla Hub VM (`nsg-hub-vm`)**
  - **Reguła `SSH`**: Zezwala na ruch przychodzący na porcie 22 (SSH) wyłącznie ze źródłowego adresu IP podanego w zmiennej `var.my_ip_address`.

- **NSG dla Private Endpoints (`nsg-spoke-private-endpoints`)**
  - **Domyślna reguła `AllowVnetInbound` jest usunięta** na rzecz bardziej restrykcyjnych reguł.
  - **Dostęp HTTP/HTTPS (80/443)**: Zezwolony ze źródła `var.my_ip_address` oraz z prywatnego IP maszyny VM w Hubie.
  - **Dostęp SMB (445)**: Zezwolony **tylko** z prywatnego IP maszyny VM w Hubie (dla Azure Files).
  - **Dostęp do SQL (1433)**: Zezwolony z prywatnego IP maszyny VM w Hubie oraz z podsieci `snet-aks-nodes`, aby umożliwić aplikacjom w AKS komunikację z bazą danych.

### 1.3. Klaster Azure Kubernetes Service (AKS)

- **Typ klastra**: Private Cluster (API Server dostępny tylko wewnątrz VNet).
- **Sieć (Azure CNI)**:
  - **Plugin**: `azure`
  - **Tryb**: `VNet`. Pody i nody otrzymują adresy IP z przestrzeni adresowej VNetu.
  - **Network Policy**: `azure` (Azure Network Policy Manager).
- **Tożsamości i Federacja**:
  - **`Workload Identity`**: Włączone (`oidc_issuer_enabled = true`). Pozwala na bezhasłowe uwierzytelnianie podów.
  - **Federated Identity Credential (FIC)**: Skonfigurowane dla tożsamości `id-aks-workload` z subjectem `system:serviceaccount:work:workload`.

### 1.4. Usługi PaaS i Private Link

Wszystkie usługi PaaS są w pełni zintegrowane z siecią prywatną.

- **Azure Key Vault**: Model RBAC. Dostęp publiczny ograniczony do IP administratora.
- **Azure Storage Account**: Udostępnia **Azure Files (SMB)**. Tożsamość `id-aks-workload` posiada uprawnienia do zarządzania (Contributor) i danych (Data Privileged Contributor).
- **Azure SQL Database**: Model **Serverless**. 
    - **Uwierzytelnianie**: Wyłącznie Entra ID (Azure AD).
    - **Identity**: Serwer posiada własną tożsamość `sql-user-mi` z rolą `Directory Readers`.
    - **Admin AD**: Tożsamość maszyny VM (`id-vm-workload`) jest ustawiona jako Active Directory Admin serwera SQL.

### 1.5. Tożsamości Zarządzane (Managed Identities)

Architektura wykorzystuje pięć tożsamości zarządzanych:

- **`id-aks-cluster`**: Zarządzanie klastrem (Control Plane).
- **`id-aks-kubelet`**: Pobieranie obrazów i operacje na węzłach.
- **`id-aks-workload`**: Tożsamość dla Podów. Posiada dostęp do Key Vault i Storage.
- **`id-vm-workload`**: Tożsamość dla maszyny Jumpbox. Posiada rolę `Directory Readers` oraz `AKS Cluster Admin`, co pozwala na bezhasłowe zarządzanie klastrem i bazą SQL.
- **`sql-user-mi`**: Tożsamość przypisana do serwera SQL. Posiada rolę `Directory Readers`, co umożliwia silnikowi bazy danych weryfikację tożsamości Entra ID (użytkowników zewnętrznych).

---

## 2. Kluczowe konfiguracje bezpieczeństwa

### 2.1. Directory Readers (Entra ID)
Obie tożsamości (`id-vm-workload` oraz `sql-user-mi`) mają przypisaną rolę katalogową **Directory Readers**. Jest to niezbędne, aby:
1. Administrator (VM) mógł dodawać użytkowników zewnętrznych do bazy danych (`CREATE USER ... FROM EXTERNAL PROVIDER`).
2. Serwer SQL mógł wyszukiwać i weryfikować te tożsamości w Entra ID.

### 2.2. Workload Identity
Konfiguracja opiera się na zaufaniu federacyjnym między klastrem AKS (OIDC Issuer) a Entra ID. Tokeny są wstrzykiwane do podów w namespace `work` korzystających z ServiceAccount `workload`.

---

## 3. Struktura Kodu Terraform

- `identity.tf`: Definicje tożsamości, FIC oraz ról RBAC/Entra ID.
- `sql.tf`: Konfiguracja SQL Server z tożsamością i dostępem prywatnym.
- `aks-private.tf`: Konfiguracja klastra AKS w trybie prywatnym z włączonym OIDC.
- `network-*.tf`: Definicje sieci Hub, Spoke i Peeringu.
- `keyvault.tf`, `storage.tf`: Usługi PaaS zintegrowane przez Private Link.
