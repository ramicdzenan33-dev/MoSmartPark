using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace MoSmartPark.Services.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddDatabaseServices(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<MoSmartParkDbContext>(options =>
                options.UseSqlServer(connectionString));
        }

        public static void AddDatabaseMoSmartPark(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<MoSmartParkDbContext>(options =>
                options.UseSqlServer(connectionString));
        }
    }
}