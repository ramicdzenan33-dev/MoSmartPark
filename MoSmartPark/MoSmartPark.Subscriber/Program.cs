using MoSmartPark.Subscriber.Interfaces;
using MoSmartPark.Subscriber.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using DotNetEnv;

// Load .env file if it exists (for local development)
// In Docker, environment variables are provided by docker-compose
try
{
    Env.Load();
}
catch (FileNotFoundException)
{
    // .env file not found - this is OK in Docker environments
    // Environment variables will be provided by docker-compose
}

var builder = Host.CreateDefaultBuilder(args)
    .ConfigureServices((hostContext, services) =>
    {
        // Add configuration
        services.AddSingleton<IConfiguration>(hostContext.Configuration);
        
        // Add RabbitMQ services
        services.AddSingleton<IEmailSenderService, EmailSenderService>();
        services.AddHostedService<BackgroundWorkerService>();
    });

var host = builder.Build();
await host.RunAsync(); 