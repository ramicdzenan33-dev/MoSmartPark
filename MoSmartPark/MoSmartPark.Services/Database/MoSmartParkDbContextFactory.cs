using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using DotNetEnv;
using System.IO;
using System.Reflection;
using Microsoft.Extensions.Configuration;

namespace MoSmartPark.Services.Database
{
    /// <summary>
    /// Design-time factory for Entity Framework migrations.
    /// This allows EF Core tools to create a DbContext instance during migrations.
    /// </summary>
    public class MoSmartParkDbContextFactory : IDesignTimeDbContextFactory<MoSmartParkDbContext>
    {
        public MoSmartParkDbContext CreateDbContext(string[] args)
        {
            // Find the project root by looking for .env file or solution root
            // Start from the assembly location (where the compiled DLL is)
            var assemblyLocation = Assembly.GetExecutingAssembly().Location;
            var assemblyDirectory = Path.GetDirectoryName(assemblyLocation) ?? Directory.GetCurrentDirectory();
            
            // Try to find .env file by walking up from assembly directory
            var currentDir = assemblyDirectory;
            var envPath = (string?)null;
            
            // Walk up directories looking for .env file (max 5 levels up)
            for (int i = 0; i < 5 && currentDir != null; i++)
            {
                var testPath = Path.Combine(currentDir, ".env");
                if (File.Exists(testPath))
                {
                    envPath = testPath;
                    break;
                }
                currentDir = Directory.GetParent(currentDir)?.FullName;
            }
            
            // Also try current working directory (for Package Manager Console)
            if (envPath == null)
            {
                var cwdEnvPath = Path.Combine(Directory.GetCurrentDirectory(), ".env");
                if (File.Exists(cwdEnvPath))
                {
                    envPath = cwdEnvPath;
                }
            }
            
            // Try relative to current directory (multiple levels)
            if (envPath == null)
            {
                var possibleEnvPaths = new[]
                {
                    Path.Combine(Directory.GetCurrentDirectory(), ".env"),
                    Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"),
                    Path.Combine(Directory.GetCurrentDirectory(), "..", "..", ".env"),
                    Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", ".env"),
                    Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "..", ".env"),
                };

                foreach (var testPath in possibleEnvPaths)
                {
                    if (File.Exists(testPath))
                    {
                        envPath = testPath;
                        break;
                    }
                }
            }
            
            // Load .env file if found
            if (envPath != null)
            {
                try
                {
                    Env.Load(envPath);
                }
                catch
                {
                    // If loading fails, continue - environment variables might be set another way
                }
            }

            // Build connection string from .env variables with Trusted_Connection for local development
            // Design-time factory is only used locally (migrations), never in Docker
            var sqlServer = Environment.GetEnvironmentVariable("SQL__SERVER") ?? ".";
            var sqlDatabase = Environment.GetEnvironmentVariable("SQL__DATABASE") ?? "MoSmartParkDb";
            var sqlUser = Environment.GetEnvironmentVariable("SQL__USER") ?? "sa";
            var sqlPassword = Environment.GetEnvironmentVariable("SQL__PASSWORD") ?? "";
            
            var connectionString = $"Server={sqlServer};Database={sqlDatabase};User Id={sqlUser};Password={sqlPassword};TrustServerCertificate=True;Trusted_Connection=True;";

            var optionsBuilder = new DbContextOptionsBuilder<MoSmartParkDbContext>();
            optionsBuilder.UseSqlServer(connectionString);

            return new MoSmartParkDbContext(optionsBuilder.Options);
        }
    }
}
