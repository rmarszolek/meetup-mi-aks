terraform output > outputs.txt

sudo apt-get update
sudo apt-get install bzip2 ca-certificates curl -y

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt update && sudo apt install bzip2 -y
# 1. Pobieramy konkretną wersję (zastępujemy snap/apt)
wget https://github.com/microsoft/go-sqlcmd/releases/download/v1.6.0/sqlcmd-v1.6.0-linux-amd64.tar.bz2

# 2. Rozpakowujemy (teraz zadziała, bo mamy bzip2)
tar -xvf sqlcmd-v1.6.0-linux-amd64.tar.bz2

# 3. Instalujemy w systemie
sudo mv sqlcmd /usr/local/bin/sqlcmd
sudo chmod +x /usr/local/bin/sqlcmd

# 4. Sprzątamy po instalacji (Dobra praktyka)
rm sqlcmd-v1.6.0-linux-amd64.tar.bz2


sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubectl
kubectl version --client
tdnf install bind-utils -y
# 5. Odświeżamy ścieżki (Twoja linia 23)
hash -r

# podpięcia tożsamości zarządzanej do VM
az login --identity  --client-id <client_id_twojej_tozsamosci>
# 6. Sprawdzamy czy działa
# sqlcmd -S <twoj_serwer>.database.windows.net -d master -U <login_admina> -P '<haslo>' -Q "CREATE LOGIN [NowyUser] WITH PASSWORD = 'SilneHaslo123!';"
sqlcmd -S sql-dev-g7s88q.database.windows.net -d master -U sqladmin -P '!ImiGo=OpV#MMWY:mQzo]tqh'
# sql-dev-0qtv0a.database.windows.net  - z outputs terrafrom , terraform output 



# 1. Logowanie do Azure (Device Code)
az login --identity --client-id e1f63376-55ab-4e3c-8492-b747f5897e59

# 2. Połączenie z bazą (automatycznie bierze token z az login)
sqlcmd -S sqlcmd -S sql-dev-4b3xkb.database.windows.net -d master  --authentication-method=ActiveDirectoryManagedIdentity -U e1f63376-55ab-4e3c-8492-b747f5897e59 

 sqlcmd -S sql-dev-4b3xkb.database.windows.net \
              -d sqldb-dev-main \
              --authentication-method=ActiveDirectoryDefault
# sql-dev-0qtv0a.database.windows.net  - z outputs terrafrom , terraform output 
CREATE USER [id-aks-workload] FROM EXTERNAL PROVIDER;
GO
ALTER ROLE db_owner ADD MEMBER [id-aks-workload];
GO
ALTER ROLE dbmanager ADD MEMBER [id-aks-workload];
GO

SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = 'id-aks-workload';
GO

# idziemyna cluster 

kubectl version --client

sudo az aks install-cli

az aks get-credentials --resource-group rg-aks-dev-g7s88q --name aks-dev-g7s88q

kubectl get nodes
# modyfikacja i przystosowanie all.yamk 
kubectl apply -f all.yaml
kubectl get pods -n work -o wide

kubectl exec -n work -it kv-client -- /bin/bash

   az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
   az keyvault secret list --vault-name $KEY_VAULT_NAME --output table
   az keyvault secret show   --vault-name $KEY_VAULT_NAME  --name "sql-connection-string" --query "value" -o tsv
   az keyvault secret show   --vault-name $KEY_VAULT_NAME  --name "sql-admin-password" --query "value" -o tsv
   az keyvault secret set   --vault-name $KEY_VAULT_NAME   --name "SekretTestowy"   --value "ToJestSuperTajneHaslo123!"
    az keyvault secret list --vault-name $KEY_VAULT_NAME --output table
   az keyvault secret show   --vault-name $KEY_VAULT_NAME   --name "SekretTestowy"   --query "value" -o tsv

kubectl exec -n work -it sql-client-debug -- /bin/bash
   #czy jest token sie generuje
curl -s -H "Metadata: true" \
"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://database.windows.net/&client_id=$CLIENT_ID"



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


echo "Łączenie jako Client ID: $AZURE_CLIENT_ID"

sqlcmd -S sql-dev-4b3xkb.database.windows.net \
              -d sqldb-dev-main \
              --authentication-method=ActiveDirectoryDefault

# jesteś w baziedanych 

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

nslookup sql-dev-endyvo.database.windows.net


 kubectl exec -it storage-client -n work -- /bin/bash

 az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
#tworzymy shar 
az storage share-rm create   --resource-group $RESOURCE_GROUP_NAME   --storage-account $STORAGE_ACCOUNT_NAME   --name "moj-share-testowy"   --quota 1

echo "To jest test z Poda Workload Identity" > /tmp/testfile.txt

az storage file upload   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --source "/tmp/testfile.txt"   --path "testfile.txt"   --auth-mode login --enable-file-backup-request-intent

az storage file list   --account-name $STORAGE_ACCOUNT_NAME   --share-name "moj-share-testowy"   --auth-mode login   --output table --enable-file-backup-request-intent

wracamy naubuntu 
curl -s -H "Metadata: true" \
"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://database.windows.net/&client_id=$CLIENT_ID"

kubectl describe pod workload-pod -n work

kubectl exec -it workload-pod -n work -- /bin/bash

az login --service-principal   --username "$AZURE_CLIENT_ID"   --tenant "$AZURE_TENANT_ID"   --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"
cat $AZURE_FEDERATED_TOKEN_FILE

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash