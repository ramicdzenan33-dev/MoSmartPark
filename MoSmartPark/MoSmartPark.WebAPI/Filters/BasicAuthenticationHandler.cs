using MoSmartPark.Model.Requests;
using MoSmartPark.Services.Interfaces;
using MoSmartPark.Services.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;

namespace MoSmartPark.WebAPI.Filters
{
    public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        private readonly IUserService _userService;

        public BasicAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            ISystemClock clock,
            IUserService userService)
            : base(options, logger, encoder, clock)
        {
            _userService = userService;
        }

        protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!Request.Headers.ContainsKey("Authorization"))
                return AuthenticateResult.NoResult();

            try
            {
                var authHeader = AuthenticationHeaderValue.Parse(Request.Headers["Authorization"]);
                
                // If scheme is not "Basic", return NoResult (let other handlers try)
                if (authHeader.Scheme != "Basic")
                    return AuthenticateResult.NoResult();
                
                // If parameter is null or empty, return NoResult
                if (string.IsNullOrEmpty(authHeader.Parameter))
                    return AuthenticateResult.NoResult();
                
                var credentialsBytes = Convert.FromBase64String(authHeader.Parameter);
                var credentials = Encoding.UTF8.GetString(credentialsBytes).Split(':');
                
                // If credentials are malformed, return NoResult
                if (credentials.Length != 2 || string.IsNullOrEmpty(credentials[0]) || string.IsNullOrEmpty(credentials[1]))
                    return AuthenticateResult.NoResult();
                
                var username = credentials[0];
                var password = credentials[1];

                var user = await _userService.AuthenticateAsync(new UserLoginRequest { Username = username, Password = password });

                if (user == null)
                    return AuthenticateResult.Fail("Invalid credentials");

                // Create a list to hold all claims
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.GivenName, user.FirstName),
                    new Claim(ClaimTypes.Surname, user.LastName),
                    new Claim(ClaimTypes.Email, user.Email)
                };

                // Add role claims
                if (user.Roles != null)
                {
                    foreach (var role in user.Roles)
                    {
                        claims.Add(new Claim(ClaimTypes.Role, role.Name));
                    }
                }

                var identity = new ClaimsIdentity(claims, Scheme.Name);
                var principal = new ClaimsPrincipal(identity);
                var ticket = new AuthenticationTicket(principal, Scheme.Name);

                return AuthenticateResult.Success(ticket);
            }
            catch
            {
                // If parsing fails, return NoResult instead of failing
                return AuthenticateResult.NoResult();
            }
        }
    }
}

