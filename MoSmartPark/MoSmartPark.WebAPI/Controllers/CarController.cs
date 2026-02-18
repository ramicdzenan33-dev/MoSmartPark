using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class CarController : BaseCRUDController<CarResponse, CarSearchObject, CarUpsertRequest, CarUpsertRequest>
    {
        private readonly ICarService _carService;
        private readonly INotificationService _notificationService;
        private readonly IUserService _userService;
        private readonly IUserPreferencesService _userPreferencesService;

        public CarController(ICarService service, INotificationService notificationService, IUserService userService, IUserPreferencesService userPreferencesService) : base(service)
        {
            _carService = service;
            _notificationService = notificationService;
            _userService = userService;
            _userPreferencesService = userPreferencesService;
        }

        [AllowAnonymous]
        public override async Task<PagedResult<CarResponse>> Get([FromQuery] CarSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<CarResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        public override async Task<CarResponse> Create([FromBody] CarUpsertRequest request)
        {
            var car = await base.Create(request);

            // Notify admins who have "Cars" notifications enabled
            var adminSearch = new UserSearchObject { RetrieveAll = true };
            var admins = await _userService.GetAsync(adminSearch);

            foreach (var admin in admins.Items ?? new List<UserResponse>())
            {
                var hasAdminRole = admin.Roles?.Any(r => r.Name == "Administrator") ?? false;
                if (!hasAdminRole)
                    continue;

                var prefs = await _userPreferencesService.GetByUserIdAsync(admin.Id);
                if (!prefs.NotifyCars)
                    continue;

                await _notificationService.CreateNotificationAsync(
                    admin.Id,
                    "new_car",
                    "New Car Registered",
                    $"A new car has been registered: {car.BrandName} {car.Model} ({car.LicensePlate}).",
                    "Car",
                    car.Id
                );
            }

            return car;
        }

        [HttpPut("{id}")]
        public override async Task<CarResponse?> Update(int id, [FromBody] CarUpsertRequest request)
        {
            var car = await base.Update(id, request);

            if (car != null)
            {
                var adminSearch = new UserSearchObject { RetrieveAll = true };
                var admins = await _userService.GetAsync(adminSearch);

                foreach (var admin in admins.Items ?? new List<UserResponse>())
                {
                    var hasAdminRole = admin.Roles?.Any(r => r.Name == "Administrator") ?? false;
                    if (!hasAdminRole)
                        continue;

                    var prefs = await _userPreferencesService.GetByUserIdAsync(admin.Id);
                    if (!prefs.NotifyCars)
                        continue;

                    await _notificationService.CreateNotificationAsync(
                        admin.Id,
                        "car_updated",
                        "Car Information Updated",
                        $"Car information updated: {car.BrandName} {car.Model} ({car.LicensePlate}).",
                        "Car",
                        car.Id
                    );
                }
            }

            return car;
        }
    }
}

