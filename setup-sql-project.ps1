# Create folder structure
New-Item -ItemType Directory -Path "sql-database-project\db\dbo\storedprocedures" -Force | Out-Null
New-Item -ItemType Directory -Path "sql-database-project\db\dbo\types" -Force | Out-Null
New-Item -ItemType Directory -Path "sql-database-project\db\schema" -Force | Out-Null

# Create Dockerfile
@'
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-stage

WORKDIR /src
COPY db/ ./db/
WORKDIR /src/db

RUN dotnet build database.csproj -o /dacpac-output

FROM mcr.microsoft.com/mssql/server:2019-latest

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=YourStrongPassword1!
ENV MSSQL_PID=Express

USER root
RUN apt-get update && apt-get install -y unzip wget

RUN wget https://aka.ms/sqlpackage-linux -O sqlpackage.zip && `
    unzip sqlpackage.zip -d /sqlpackage && `
    chmod +x /sqlpackage/sqlpackage

ENV PATH="/sqlpackage:${PATH}"

COPY --from=build-stage /dacpac-output/ /dacpac/
COPY deploy-db.sh /deploy-db.sh
RUN chmod +x /deploy-db.sh

USER mssql
CMD ["/deploy-db.sh"]
'@ | Set-Content "sql-database-project\Dockerfile"

# Create docker-compose.yml
@'
version: "3.9"
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: sqlserver
    ports:
      - "1433:1433"
    environment:
      SA_PASSWORD: "YourStrongPassword1!"
      ACCEPT_EULA: "Y"
      MSSQL_PID: "Express"
    healthcheck:
      test: ["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "YourStrongPassword1!", "-Q", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 5

  dacpac-deployer:
    build: .
    depends_on:
      sqlserver:
        condition: service_healthy
    environment:
      SA_PASSWORD: "YourStrongPassword1!"
'@ | Set-Content "sql-database-project\docker-compose.yml"

# Create deploy-db.sh
@'
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
'@ | Set-Content "sql-database-project\deploy-db.sh"

# Create database.csproj
@'
<Project Sdk="MSBuild.Sdk.SqlProj/3.0.0">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <SqlServerVersion>Sql150</SqlServerVersion>
    <Name>database</Name>
  </PropertyGroup>
  <ItemGroup>
    <Build Include="schema/**/*.sql" />
    <Build Include="dbo/types/**/*.sql" />
    <Build Include="dbo/storedprocedures/**/*.sql" />
  </ItemGroup>
</Project>
'@ | Set-Content "sql-database-project\db\database.csproj"

# Create schema/Users.sql
@'
CREATE TABLE dbo.Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100),
    Email NVARCHAR(200),
    CreatedAt DATETIME2
);
GO
'@ | Set-Content "sql-database-project\db\schema\Users.sql"

# Create types/UserInputType.sql
@'
CREATE TYPE dbo.UserInputType AS TABLE (
    Username NVARCHAR(100),
    Email NVARCHAR(200),
    CreatedAt DATETIME2
);
GO
'@ | Set-Content "sql-database-project\db\dbo\types\UserInputType.sql"

# Create storedprocedures/spInsertUsers.sql
@'
CREATE PROCEDURE dbo.spInsertUsers
    @NewUsers dbo.UserInputType READONLY
AS
BEGIN
    INSERT INTO dbo.Users (Username, Email, CreatedAt)
    SELECT Username, Email, CreatedAt FROM @NewUsers;
END
GO
'@ | Set-Content "sql-database-project\db\dbo\storedprocedures\spInsertUsers.sql"

Write-Host "`n✅ Project scaffold created under 'sql-database-project'."
