# Infrastruktura Azure dla AKS w topologii Hub & Spoke

Projekt Terraform wdraża bezpieczną infrastrukturę Azure w modelu Hub & Spoke, zoptymalizowaną pod **AKS Workload Identity** oraz prywatną łączność z usługami PaaS (SQL, Key Vault, Storage).

## Główne Nowości w Architekturze
- **Pełna Tożsamość Zarządzana**: Brak haseł w komunikacji. Nawet maszyna Jumpbox i Serwer SQL korzystają z Managed Identities.
- **Entra ID dla SQL**: Autoryzacja do bazy danych odbywa się wyłącznie przez Entra ID (Azure AD).
- **Directory Readers**: Automatyczna aktywacja roli w tenancie dla tożsamości zarządzanych.
- **Private AKS**: Klaster jest całkowicie odizolowany od internetu (Private Cluster).

## Wymagania wstępne
- Azure CLI, Terraform >= 1.0.
- Uprawnienia **Global Administrator** lub **Privileged Role Administrator** w Entra ID (wymagane do nadania roli `Directory Readers`).

## Szybki Start

1. **Inicjalizacja i Apply:**
   ```bash
   terraform init
   ```
   Utwórz `terraform.tfvars` z `subscription_id` oraz `my_ip_address`, a następnie:
   ```bash
   terraform apply
   ```

2. **Dostęp do klastra (z maszyny VM):**
   Połącz się przez SSH z VM w Hubie (użyj `vm_ssh_command` z outputów) i pobierz poświadczenia:
   ```bash
   az login --identity --username <vm_workload_identity_client_id>
   az aks get-credentials --resource-group <rg-name> --name <aks-name>
   ```

3. **Konfiguracja SQL (Krok Ręczny):**
   Mimo że infrastruktura jest gotowa, musisz raz dodać tożsamość podu do bazy danych. Z maszyny VM:
   ```bash
   # Logowanie do SQL jako Admin AD
   sqlcmd -S <sql_server_fqdn> -d <sql_db_name> --authentication-method=ActiveDirectoryDefault

   # Wewnątrz bazy danych:
   CREATE USER [id-aks-workload] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_owner ADD MEMBER [id-aks-workload];
   GO
   ```

## Kluczowe Outputy
Po zakończeniu wdrożenia zanotuj:
- `vm_workload_identity_client_id`: Używane do `az login --identity` na maszynie VM.
- `sql_server_identity_client_id`: Client ID tożsamości samego serwera SQL.
- `aks_workload_identity_client_id`: Client ID, który należy wpisać w adnotacjach `ServiceAccount` w Kubernetes.

## Testowanie Workload Identity
W folderze `yaml/` znajdują się przykładowe manifesty. Pamiętaj o aktualizacji `client-id` w `serviceaccount.yaml` przed ich nałożeniem:
```bash
kubectl apply -f yaml/workspace.yaml
kubectl apply -f yaml/serviceaccount.yaml
kubectl apply -f yaml/pod.yaml
```

Wewnątrz podu możesz przetestować dostęp do SQL:
```bash
sqlcmd -S <fqdn> -d <db> --authentication-method=ActiveDirectoryDefault
```

## Czyszczenie
```bash
terraform destroy
```
