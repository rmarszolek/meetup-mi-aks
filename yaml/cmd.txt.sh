kubectl exec -it sql-client-debug -n work -- /bin/bash

#czy jest token w podzie
curl -s -H "Metadata: true" \
"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://database.windows.net/&client_id=$CLIENT_ID"

# --- START SKRYPTU ---


# 1. Instalujemy bzip2 (Wymagane do rozpakowania)
# Obraz azure-cli to zazwyczaj Mariner, więc tdnf jest pierwszy
if command -v tdnf &> /dev/null; then
    tdnf install bzip2 tar -y
elif command -v apt-get &> /dev/null; then
    apt-get update && apt-get install bzip2 -y
fi

# 2. Pobieramy sqlcmd do /tmp (bezpieczny katalog)
cd /tmp
curl -L -o sqlcmd.tar.bz2 https://github.com/microsoft/go-sqlcmd/releases/download/v1.6.0/sqlcmd-v1.6.0-linux-amd64.tar.bz2

# 3. Rozpakowujemy
tar -xvf sqlcmd.tar.bz2

# 4. Przenosimy do ścieżki systemowej (Teraz zadziała, bo FS nie jest ReadOnly)
chmod +x sqlcmd
mv sqlcmd /usr/local/bin/

# 5. TEST POŁĄCZENIA
# Używamy zmiennej $AZURE_CLIENT_ID zaciągniętej z konfiguracji Poda!
echo "Łączenie jako Client ID: $AZURE_CLIENT_ID"

sqlcmd -S sql-dev-bbscv6.database.windows.net   -d master    authentication-method=ActiveDirectoryDefault       -U $AZURE_CLIENT_ID

sqlcmd -S sql-dev-bbscv6.database.windows.net \
              -d sqldb-dev-main \
              --authentication-method=ActiveDirectoryDefault
# --- KONIEC SKRYPTU ---

CREATE TABLE UsersTest (
         UserId INT PRIMARY KEY IDENTITY(1,1),
         FirstName NVARCHAR(50) NOT NULL,
         LastName NVARCHAR(50) NOT NULL,
         Email NVARCHAR(100),
         CreatedAt DATETIME DEFAULT GETDATE());
    GO

    INSERT INTO UsersTest (FirstName, LastName, Email)
    VALUES ('Jan', 'Kowalski', 'jan.kowalski@example.com');
    GO

    SELECT * FROM UsersTest;
    GO
1> CREATE DATABASE DemoBaza2;
2> GO

-- Lista tabel w bazie
SELECT * FROM sys.tables;
GO

USE master;
GO
DROP DATABASE DemoBaza;
GO
EXIT

tdnf install bind-utils -y


nslookup sql-dev-5oojdl.database.windows.net
nslookup stdevno2tn5.file.core.windows.net
nslookup kv-dev-neetay.vault.azure.net

kubectl exec -it kv-client -n work -- /bin/bash

   az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
   az keyvault secret list --vault-name kv-dev-vcfggc --output table
   az keyvault secret show   --vault-name kv-dev-vcfggc  --name "sql-connection-string" --query "value" -o tsv
   az keyvault secret show   --vault-name kv-dev-vcfggc  --name "sql-admin-password" --query "value" -o tsv
   az keyvault secret set   --vault-name kv-dev-vcfggc   --name "SekretTestowy"   --value "ToJestSuperTajneHaslo123!"
   az keyvault secret show   --vault-name kv-dev-vcfggc   --name "SekretTestowy"   --query "value" -o tsv


    kubectl exec -it storage-client -n work -- /bin/bash

    az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
    
do weryfikacji 
    az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
    az storage share-rm create   --resource-group $RESOURCE_GROUP_NAME   --storage-account $STORAGE_ACCOUNT_NAME   --name "moj-share-testowy"   --quota 1
    4  azlogout
    5  az logout
    6  exit
    7  az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
    8   az storage share-rm create   --resource-group $RESOURCE_GROUP_NAME   --storage-account $STORAGE_ACCOUNT_NAME   --name "moj-share-testowy"   --quota 1
    9  # 1. Tworzymy plik
   10  echo "To jest test z Poda Workload Identity" > /tmp/testfile.txt
   11  # 2. Wysyłamy do udziału (UWAGA na --auth-mode login)
   12  az storage file upload   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --source "/tmp/testfile.txt"   --path "testfile.txt"   --auth-mode login
   13  ls
   14  cat /tmp/testfile.txt
   15  az storage file upload   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --source "/tmp/testfile.txt"   --path "testfile.txt"   --auth-mode login
   16  az storage file upload   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --source "/tmp/testfile.txt"   --path "testfile.txt"   --auth-mode login --enable-file-backup-request-inten
   17  az storage file list   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --auth-mode login   --output table
   18  az storage file list   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy" --enable-file-backup-request-intent  --auth-mode login   --output table
   19  az storage file download   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --path "testfile.txt"   --dest "/tmp/nowytestfile.txt"   --auth-mode login   --enable-file-backup-request-intent
   20  cat /tmp/nowytestfile.txt
   21  history


   do zrobienia 
   kubectl exec -it workload-pod -n work -- /bin/bash
   env | grep AZURE_FEDERATED_TOKEN_FILE
   cat $AZURE_FEDERATED_TOKEN_FILE
   dekoduj token - https://everythingwebsite.dev/pl/tools/jwt-decoder 