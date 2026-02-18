using MoSmartPark.Services.Database;
using Mapster;
using Microsoft.AspNetCore.Authentication;
using Microsoft.OpenApi.Models;
using MoSmartPark.WebAPI.Filters;
using MoSmartPark.Services.Services;
using MoSmartPark.Services.Interfaces;
using System.Reflection;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using DotNetEnv;

// Load .env file if it exists (for local development)
// In Docker, environment variables are provided by docker-compose
try
{
    // Try multiple possible paths for .env file
    var possibleEnvPaths = new[]
    {
        Path.Combine(Directory.GetCurrentDirectory(), ".env"),
        Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"),
        Path.Combine(Directory.GetCurrentDirectory(), "..", "..", ".env"),
    };

    bool envLoaded = false;
    foreach (var envPath in possibleEnvPaths)
    {
        if (File.Exists(envPath))
        {
            Env.Load(envPath);
            envLoaded = true;
            break;
        }
    }

    // If no .env file found in common locations, try default location
    if (!envLoaded)
    {
        Env.Load();
    }
}
catch (FileNotFoundException)
{
    // .env file not found - this is OK in Docker environments
    // Environment variables will be provided by docker-compose
}

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IRoleService, RoleService>();
builder.Services.AddTransient<IGenderService, GenderService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<IParkingSpotTypeService, ParkingSpotTypeService>();
builder.Services.AddTransient<IParkingZoneService, ParkingZoneService>();
builder.Services.AddTransient<IParkingSpotService, ParkingSpotService>();
builder.Services.AddTransient<IBrandService, BrandService>();
builder.Services.AddTransient<IColorService, ColorService>();
builder.Services.AddTransient<ICarService, CarService>();
builder.Services.AddTransient<IReservationTypeService, ReservationTypeService>();
builder.Services.AddTransient<IReservationService, ReservationService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IBusinessReportService, BusinessReportService>();
builder.Services.AddTransient<IStripePaymentService, StripePaymentService>();
builder.Services.AddTransient<INotificationService, NotificationService>();
builder.Services.AddTransient<IUserPreferencesService, UserPreferencesService>();


// Configure database
// Try to get connection string from configuration first
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// If not found (local development), build from .env variables with Trusted_Connection
// In Docker, the full connection string is provided via docker-compose environment
if (string.IsNullOrWhiteSpace(connectionString))
{
    var sqlServer = Environment.GetEnvironmentVariable("SQL__SERVER") ?? ".";
    var sqlDatabase = Environment.GetEnvironmentVariable("SQL__DATABASE") ?? "MoSmartParkDb";
    var sqlUser = Environment.GetEnvironmentVariable("SQL__USER") ?? "sa";
    var sqlPassword = Environment.GetEnvironmentVariable("SQL__PASSWORD") ?? "";
    
    connectionString = $"Server={sqlServer};Database={sqlDatabase};User Id={sqlUser};Password={sqlPassword};TrustServerCertificate=True;Trusted_Connection=True;";
}

builder.Services.AddDatabaseServices(connectionString);


// Add configuration
builder.Services.AddSingleton<IConfiguration>(builder.Configuration);

builder.Services.AddMapster();

builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

builder.Services.AddControllers(x =>
    {
        x.Filters.Add<ExceptionFilter>();
    }
);

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

// Za dodavanje opisnog teksta pored swagger call-a
var xmlFilename = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";

builder.Services.AddSwaggerGen(c =>
{
    c.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, xmlFilename));

    c.AddSecurityDefinition("BasicAuthentication", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "basic",
        In = ParameterLocation.Header,
        Description = "Basic Authorization header using the Bearer scheme."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "BasicAuthentication" } },
            new string[] { }
        }
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var dataContext = scope.ServiceProvider.GetRequiredService<MoSmartParkDbContext>();


    var pendingMigrations = dataContext.Database.GetPendingMigrations().Any();

    if (pendingMigrations)
    {

        dataContext.Database.Migrate();


    }
    
    // Run dynamic data seeder
    await DynamicDataSeeder.SeedAsync(dataContext);
    
    // Train the recommender model in background after startup
    _ = Task.Run(async () =>  // The underscore tells the compiler we're intentionally ignoring the result
    {
        // Wait a bit for the app to fully start
        await Task.Delay(2000);
        using (var trainingScope = app.Services.CreateScope())
        {
            ParkingSpotService.TrainRecommenderAtStartup(trainingScope.ServiceProvider);
        }
    });
}

app.Run();
