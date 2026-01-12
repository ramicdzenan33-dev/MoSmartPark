using EasyNetQ;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.Versioning;
using System.Linq;
using MoSmartPark.Subscriber.Models;
using MoSmartPark.Subscriber.Interfaces;
using System.Net.Sockets;
using System.Net;

namespace MoSmartPark.Subscriber.Services
{
    public class BackgroundWorkerService : BackgroundService
    {
        private readonly ILogger<BackgroundWorkerService> _logger;
        private readonly IEmailSenderService _emailSender;
        private readonly string _host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
        private readonly string _username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
        private readonly string _password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
        private readonly string _virtualhost = Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

        public BackgroundWorkerService(
            ILogger<BackgroundWorkerService> logger,
            IEmailSenderService emailSender)
        {
            _logger = logger;
            _emailSender = emailSender;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Check internet connectivity to smtp.gmail.com
            try
            {
                var addresses = await Dns.GetHostAddressesAsync("smtp.gmail.com");
                _logger.LogInformation($"smtp.gmail.com resolved to: {string.Join(", ", addresses.Select(a => a.ToString()))}");
                using (var client = new TcpClient())
                {
                    var connectTask = client.ConnectAsync("smtp.gmail.com", 587);
                    var timeoutTask = Task.Delay(5000, stoppingToken);
                    var completed = await Task.WhenAny(connectTask, timeoutTask);
                    if (completed == connectTask && client.Connected)
                    {
                        _logger.LogInformation("Successfully connected to smtp.gmail.com:587");
                    }
                    else
                    {
                        _logger.LogError("Failed to connect to smtp.gmail.com:587 (timeout or error)");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Internet connectivity check failed: {ex.Message}");
            }

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var bus = RabbitHutch.CreateBus($"host={_host};virtualHost={_virtualhost};username={_username};password={_password}"))
                    {
                        // Subscribe to reservation notifications
                        bus.PubSub.Subscribe<ReservationNotification>("Reservation_Notifications", HandleReservationMessage);

                        _logger.LogInformation("Reservation service is awaiting incoming requests...");
                        await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                    }
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError($"Error in RabbitMQ listener: {ex.Message}");
                }
            }
        }

        private async Task HandleReservationMessage(ReservationNotification notification)
        {
            var reservation = notification.Reservation;

            if (string.IsNullOrWhiteSpace(reservation.UserEmail))
            {
                _logger.LogWarning("Reservation notification missing user email.");
                return;
            }

            var subject = "Your Parking Reservation Confirmation - MoSmartPark";
            
            // Create a nicely formatted HTML email
            var htmlMessage = $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }}
        .container {{
            background-color: #ffffff;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px 10px 0 0;
            margin: -30px -30px 30px -30px;
            text-align: center;
        }}
        .header h1 {{
            margin: 0;
            font-size: 24px;
        }}
        .content {{
            margin: 20px 0;
        }}
        .info-box {{
            background-color: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin: 15px 0;
            border-radius: 5px;
        }}
        .info-row {{
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #e0e0e0;
        }}
        .info-row:last-child {{
            border-bottom: none;
        }}
        .label {{
            font-weight: bold;
            color: #555;
        }}
        .value {{
            color: #333;
        }}
        .price-box {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            margin: 20px 0;
        }}
        .price-box .price-label {{
            font-size: 14px;
            opacity: 0.9;
        }}
        .price-box .price-value {{
            font-size: 32px;
            font-weight: bold;
            margin-top: 5px;
        }}
        .footer {{
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
            text-align: center;
            color: #777;
            font-size: 12px;
        }}
        .button {{
            display: inline-block;
            padding: 12px 30px;
            background-color: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
        }}
    </style>
</head>
<body>
    <div class=""container"">
        <div class=""header"">
            <h1>🎉 Reservation Confirmed!</h1>
        </div>
        
        <div class=""content"">
            <p>Hello <strong>{reservation.UserFullName}</strong>,</p>
            
            <p>Your parking reservation has been successfully confirmed! We're excited to have you park with us.</p>
            
            <div class=""info-box"">
                <div class=""info-row"">
                    <span class=""label"">Vehicle:</span>
                    <span class=""value"">{reservation.CarModel} ({reservation.CarLicensePlate})</span>
                </div>
                <div class=""info-row"">
                    <span class=""label"">Parking Spot:</span>
                    <span class=""value"">{reservation.ParkingSpotNumber}</span>
                </div>
                <div class=""info-row"">
                    <span class=""label"">Zone:</span>
                    <span class=""value"">{reservation.ParkingZoneName}</span>
                </div>
                <div class=""info-row"">
                    <span class=""label"">Reservation Type:</span>
                    <span class=""value"">{reservation.ReservationTypeName}</span>
                </div>
                <div class=""info-row"">
                    <span class=""label"">Start Date:</span>
                    <span class=""value"">{reservation.StartDate:MMMM dd, yyyy 'at' HH:mm}</span>
                </div>
                <div class=""info-row"">
                    <span class=""label"">End Date:</span>
                    <span class=""value"">{reservation.EndDate:MMMM dd, yyyy 'at' HH:mm}</span>
                </div>
            </div>
            
            <div class=""price-box"">
                <div class=""price-label"">Total Amount</div>
                <div class=""price-value"">${reservation.FinalPrice:F2}</div>
            </div>
            
            <p style=""margin-top: 20px;"">Please arrive on time and park in your assigned spot. If you have any questions or need to modify your reservation, please contact our support team.</p>
            
            <p>We look forward to serving you!</p>
        </div>
        
        <div class=""footer"">
            <p><strong>MoSmartPark Team</strong></p>
            <p>Thank you for choosing MoSmartPark for your parking needs.</p>
        </div>
    </div>
</body>
</html>";

            // Plain text version for email clients that don't support HTML
            var plainTextMessage = $@"Hello {reservation.UserFullName},

Your parking reservation has been successfully confirmed!

RESERVATION DETAILS:
- Vehicle: {reservation.CarModel} ({reservation.CarLicensePlate})
- Parking Spot: {reservation.ParkingSpotNumber}
- Zone: {reservation.ParkingZoneName}
- Reservation Type: {reservation.ReservationTypeName}
- Start Date: {reservation.StartDate:MMMM dd, yyyy 'at' HH:mm}
- End Date: {reservation.EndDate:MMMM dd, yyyy 'at' HH:mm}
- Total Amount: ${reservation.FinalPrice:F2}

Please arrive on time and park in your assigned spot. If you have any questions or need to modify your reservation, please contact our support team.

We look forward to serving you!

Best regards,
MoSmartPark Team";

            try
            {
                await _emailSender.SendEmailAsync(reservation.UserEmail, subject, htmlMessage, isHtml: true);
                _logger.LogInformation($"Reservation notification sent to: {reservation.UserEmail}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Failed to send reservation email to {reservation.UserEmail}: {ex.Message}");
            }
        }
    }
}