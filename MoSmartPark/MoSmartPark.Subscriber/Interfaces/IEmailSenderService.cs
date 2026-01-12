using System.Threading.Tasks;

namespace MoSmartPark.Subscriber.Interfaces
{
    public interface IEmailSenderService
    {
        Task SendEmailAsync(string email, string subject, string message, bool isHtml = false);
    }
}
