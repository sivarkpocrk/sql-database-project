# Variables
$projectRoot = "sql-ef-api"
$repoName = "sql-ef-api"
$gitUser = "sivarkpocrk"
$remoteUrl = "git@github.com:sivarkpocrk/sql-ef-api.git"

# Create folder structure
New-Item -Path $projectRoot -ItemType Directory -Force
New-Item -Path "$projectRoot\Models" -ItemType Directory -Force
New-Item -Path "$projectRoot\Controllers" -ItemType Directory -Force
New-Item -Path "$projectRoot\Data" -ItemType Directory -Force
New-Item -Path "$projectRoot" -Name "Dockerfile" -ItemType File
New-Item -Path "$projectRoot" -Name "docker-compose.yml" -ItemType File
New-Item -Path "$projectRoot" -Name "appsettings.json" -ItemType File
New-Item -Path "$projectRoot" -Name ".gitignore" -ItemType File

# Create the EF model
@"
namespace sql_ef_api.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
    }
}
"@ | Set-Content "$projectRoot\Models\Product.cs"

# Create the DbContext
@"
using Microsoft.EntityFrameworkCore;
using sql_ef_api.Models;

namespace sql_ef_api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Product> Products => Set<Product>();
    }
}
"@ | Set-Content "$projectRoot\Data\AppDbContext.cs"

# Create the controller
@"
using Microsoft.AspNetCore.Mvc;
using sql_ef_api.Data;
using sql_ef_api.Models;

namespace sql_ef_api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProductController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IEnumerable<Product> Get() => _context.Products.ToList();
    }
}
"@ | Set-Content "$projectRoot\Controllers\ProductController.cs"

# Create the Program.cs
@"
using Microsoft.EntityFrameworkCore;
using sql_ef_api.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();
app.MapControllers();
app.Run();
"@ | Set-Content "$projectRoot\Program.cs"

# appsettings.json
@"
{
  ""ConnectionStrings"": {
    ""DefaultConnection"": ""Server=sqlserver;Database=DemoDb;User Id=sa;Password=YourStrongPassword!;""
  },
  ""Logging"": {
    ""LogLevel"": {
      ""Default"": ""Information"",
      ""Microsoft.AspNetCore"": ""Warning""
    }
  },
  ""AllowedHosts"": ""*""
}
"@ | Set-Content "$projectRoot\appsettings.json"

# Dockerfile
@"
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT [""dotnet"", ""sql-ef-api.dll""]
"@ | Set-Content "$projectRoot\Dockerfile"

# docker-compose.yml
@"
version: '3.4'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2019-latest
    environment:
      - SA_PASSWORD=YourStrongPassword!
      - ACCEPT_EULA=Y
    ports:
      - 1433:1433
    networks:
      - app-network

  api:
    build: .
    ports:
      - 5000:80
    depends_on:
      - sqlserver
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
"@ | Set-Content "$projectRoot\docker-compose.yml"

# .gitignore
@"
bin/
obj/
.vs/
*.user
*.suo
*.db
*.sqlite
*.log
"@ | Set-Content "$projectRoot\.gitignore"

# Initialize Git repo
Set-Location $projectRoot
git init
git add .
git commit -m "Initial commit with EF API and Docker setup"

# Optional: Push to GitHub
# git remote add origin $remoteUrl
# git push -u origin main
