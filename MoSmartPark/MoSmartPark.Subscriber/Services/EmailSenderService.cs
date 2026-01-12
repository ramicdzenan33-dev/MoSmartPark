using System.Net;
using System.Net.Mail;
using MoSmartPark.Subscriber.Interfaces;

namespace MoSmartPark.Subscriber.Services
{
    public class EmailSenderService : IEmailSenderService
    {
        private readonly string _gmailMail = "mosmartparksender@gmail.com";
        private readonly string _gmailPass = "ccko zune efat mibs";

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