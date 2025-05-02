FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-stage

WORKDIR /src
COPY db/ ./db/
WORKDIR /src/db

RUN dotnet build database.csproj -o /dacpac-output

FROM mcr.microsoft.com/mssql/server:2019-latest

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=TestPass@@2411
ENV MSSQL_PID=Express

USER root
RUN apt-get update && apt-get install -y \
    libunwind8 \
    unzip \
    wget

RUN echo 'Installing sqlpackage...' \
    && wget https://aka.ms/sqlpackage-linux -O sqlpackage.zip \
    && unzip sqlpackage.zip -d ./sqlpackage \
    && chmod +x ./sqlpackage/sqlpackage \
    && echo 'Done.'

ENV PATH="/sqlpackage:${PATH}"

COPY --from=build-stage /dacpac-output/ /dacpac/
COPY deploy-db.sh /deploy-db.sh
RUN chmod +x /deploy-db.sh

USER mssql
CMD ["/deploy-db.sh"]
