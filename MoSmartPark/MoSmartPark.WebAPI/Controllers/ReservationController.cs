using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ReservationController : BaseCRUDController<ReservationResponse, ReservationSearchObject, ReservationUpsertRequest, ReservationUpsertRequest>
    {
        private readonly IReservationService _reservationService;
        private readonly INotificationService _notificationService;
        private readonly IUserService _userService;
        private readonly IUserPreferencesService _userPreferencesService;

        public ReservationController(IReservationService service, INotificationService notificationService, IUserService userService, IUserPreferencesService userPreferencesService) : base(service)
        {
            _reservationService = service;
            _notificationService = notificationService;
            _userService = userService;
            _userPreferencesService = userPreferencesService;
        }

        [HttpPost]
        public override async Task<ReservationResponse> Create([FromBody] ReservationUpsertRequest request)
        {
            var reservation = await base.Create(request);

            // Notify admins who have "New Reservations" enabled in their preferences
            var adminSearch = new UserSearchObject { RetrieveAll = true };
            var admins = await _userService.GetAsync(adminSearch);

            foreach (var admin in admins.Items ?? new List<UserResponse>())
            {
                var hasAdminRole = admin.Roles?.Any(r => r.Name == "Administrator") ?? false;
                if (!hasAdminRole)
                    continue;

                var prefs = await _userPreferencesService.GetByUserIdAsync(admin.Id);
                if (!prefs.NotifyReservations)
                    continue;

                await _notificationService.CreateNotificationAsync(
                    admin.Id,
                    "new_reservation",
                    "New Reservation Created",
                    $"A new reservation has been created for parking spot {reservation.ParkingSpotNumber}.",
                    "Reservation",
                    reservation.Id
                );
            }

            return reservation;
        }
    }
}
