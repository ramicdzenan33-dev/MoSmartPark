using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class NotificationController : BaseCRUDController<NotificationResponse, NotificationSearchObject, NotificationUpsertRequest, NotificationUpsertRequest>
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService service) : base(service)
        {
            _notificationService = service;
        }

        [HttpGet("unread-count/{userId}")]
        public async Task<IActionResult> GetUnreadCount(int userId)
        {
            var count = await _notificationService.GetUnreadCountAsync(userId);
            return Ok(new { Count = count });
        }

        [HttpPut("{id}/mark-as-read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var result = await _notificationService.MarkAsReadAsync(id);
            if (!result)
                return NotFound();
            return Ok();
        }

        [HttpPut("user/{userId}/mark-all-as-read")]
        public async Task<IActionResult> MarkAllAsRead(int userId)
        {
            await _notificationService.MarkAllAsReadAsync(userId);
            return Ok();
        }
    }
}
