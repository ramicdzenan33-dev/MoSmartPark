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

        public ReservationController(IReservationService service, INotificationService notificationService, IUserService userService) : base(service)
        {
            _reservationService = service;
            _notificationService = notificationService;
            _userService = userService;
        }

        [HttpPost]
        public override async Task<ReservationResponse> Create([FromBody] ReservationUpsertRequest request)
        {
            var reservation = await base.Create(request);

            // Send notification to all admins
            var adminSearch = new UserSearchObject { RetrieveAll = true };
            var admins = await _userService.GetAsync(adminSearch);
            
            foreach (var admin in admins.Items ?? new List<UserResponse>())
            {
                var hasAdminRole = admin.Roles?.Any(r => r.Name == "Administrator") ?? false;
                if (hasAdminRole)
                {
                    await _notificationService.CreateNotificationAsync(
                        admin.Id,
                        "new_reservation",
                        "New Reservation Created",
                        $"A new reservation has been created for parking spot {reservation.ParkingSpotNumber}.",
                        "Reservation",
                        reservation.Id
                    );
                }
            }

            return reservation;
        }
    }
}
