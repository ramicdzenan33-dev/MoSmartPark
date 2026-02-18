using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ReviewController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewUpsertRequest, ReviewUpsertRequest>
    {
        private readonly IReviewService _reviewService;
        private readonly INotificationService _notificationService;
        private readonly IUserService _userService;
        private readonly IUserPreferencesService _userPreferencesService;

        public ReviewController(IReviewService service, INotificationService notificationService, IUserService userService, IUserPreferencesService userPreferencesService) : base(service)
        {
            _reviewService = service;
            _notificationService = notificationService;
            _userService = userService;
            _userPreferencesService = userPreferencesService;
        }

        [HttpPost]
        public override async Task<ReviewResponse> Create([FromBody] ReviewUpsertRequest request)
        {
            var review = await base.Create(request);

            // Notify admins who have "New Reviews" enabled in their preferences
            var adminSearch = new UserSearchObject { RetrieveAll = true };
            var admins = await _userService.GetAsync(adminSearch);

            foreach (var admin in admins.Items ?? new List<UserResponse>())
            {
                var hasAdminRole = admin.Roles?.Any(r => r.Name == "Administrator") ?? false;
                if (!hasAdminRole)
                    continue;

                var prefs = await _userPreferencesService.GetByUserIdAsync(admin.Id);
                if (!prefs.NotifyReviews)
                    continue;

                await _notificationService.CreateNotificationAsync(
                    admin.Id,
                    "new_review",
                    "New Review Submitted",
                    $"{review.UserFullName} left a {review.Rating}-star review.",
                    "Review",
                    review.Id
                );
            }

            return review;
        }
    }
}
