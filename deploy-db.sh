#!/bin/bash
echo "Waiting for SQL Server to be available..."
for i in {1..30}; do
    /opt/mssql-tools/bin/sqlcmd -S sqlserver -U sa -P "$SA_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is up!"
        break
    fi
    sleep 2
done

echo "Deploying DACPAC..."
sqlpackage /Action:Publish \
  /SourceFile:/dacpac/database.dacpac \
  /TargetServerName:sqlserver \
  /TargetDatabaseName:DemoDb \
  /TargetUser:sa \
  /TargetPassword:$SA_PASSWORD \
  /TargetTrustServerCertificate:True

echo "DACPAC deployment completed!"
