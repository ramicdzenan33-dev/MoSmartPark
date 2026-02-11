using System.Net;
using System.Net.Mail;
using MoSmartPark.Subscriber.Interfaces;
using Microsoft.Extensions.Configuration;

namespace MoSmartPark.Subscriber.Services
{
    public class EmailSenderService : IEmailSenderService
    {
        private readonly string _gmailMail;
        private readonly string _gmailPass;

        public EmailSenderService(IConfiguration configuration)
        {
            // .NET Configuration converts double underscores to colons
            // So SMTP__EMAIL in .env becomes SMTP:EMAIL in configuration
            // But we also check the direct environment variable as fallback
            _gmailMail = configuration["SMTP:EMAIL"] 
                ?? configuration["SMTP__EMAIL"]
                ?? Environment.GetEnvironmentVariable("SMTP__EMAIL")
                ?? throw new InvalidOperationException("SMTP__EMAIL configuration is missing. Please set it in .env file or environment variables.");
            
            _gmailPass = configuration["SMTP:PASSWORD"] 
                ?? configuration["SMTP__PASSWORD"]
                ?? Environment.GetEnvironmentVariable("SMTP__PASSWORD")
                ?? throw new InvalidOperationException("SMTP__PASSWORD configuration is missing. Please set it in .env file or environment variables.");
        }

        public Task SendEmailAsync(string email, string subject, string message, bool isHtml = false)
        {
            var client = new SmtpClient("smtp.gmail.com", 587)
            {
                EnableSsl = true,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(_gmailMail, _gmailPass)
            };

            var mailMessage = new MailMessage(from: _gmailMail, to: email, subject, message)
            {
                IsBodyHtml = isHtml
            };

            return client.SendMailAsync(mailMessage);
        }
    }
}