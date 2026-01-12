using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using MoSmartPark.Model;
using MoSmartPark.Subscriber.Models;
using EasyNetQ;

namespace MoSmartPark.Services.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Reservation, ReservationUpsertRequest, ReservationUpsertRequest>, IReservationService
    {
        private ReservationSearchObject? _currentSearch;

        public ReservationService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<ReservationResponse>> GetAsync(ReservationSearchObject search)
        {
            // Store current search object to use in MapToResponse
            _currentSearch = search;

            var query = _context.Reservations
                .Include(r => r.Car)
                    .ThenInclude(c => c.Brand)
                .Include(r => r.Car)
                    .ThenInclude(c => c.Color)
                .Include(r => r.Car)
                    .ThenInclude(c => c.User)
                .Include(r => r.ParkingSpot)
                    .ThenInclude(ps => ps.ParkingSpotType)
                .Include(r => r.ReservationType)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();
            var result = new PagedResult<ReservationResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };

            // Clear the stored search object after use
            _currentSearch = null;

            return result;
        }

        public override async Task<ReservationResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Reservations
                .Include(r => r.Car)
                    .ThenInclude(c => c.Brand)
                .Include(r => r.Car)
                    .ThenInclude(c => c.Color)
                .Include(r => r.Car)
                    .ThenInclude(c => c.User)
                .Include(r => r.ParkingSpot)
                    .ThenInclude(ps => ps.ParkingSpotType)
                .Include(r => r.ReservationType)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            if (search.CarId.HasValue)
            {
                query = query.Where(r => r.CarId == search.CarId.Value);
            }

            if (search.ParkingSpotId.HasValue)
            {
                query = query.Where(r => r.ParkingSpotId == search.ParkingSpotId.Value);
            }

            if (search.ReservationTypeId.HasValue)
            {
                query = query.Where(r => r.ReservationTypeId == search.ReservationTypeId.Value);
            }

            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.Car.UserId == search.UserId.Value);
            }

            if (search.StartDateFrom.HasValue)
            {
                query = query.Where(r => r.StartDate.HasValue && r.StartDate >= search.StartDateFrom.Value);
            }

            if (search.StartDateTo.HasValue)
            {
                query = query.Where(r => r.StartDate.HasValue && r.StartDate <= search.StartDateTo.Value);
            }

            if (search.EndDateFrom.HasValue)
            {
                query = query.Where(r => r.EndDate.HasValue && r.EndDate >= search.EndDateFrom.Value);
            }

            if (search.EndDateTo.HasValue)
            {
                query = query.Where(r => r.EndDate.HasValue && r.EndDate <= search.EndDateTo.Value);
            }

            return query;
        }

        protected override ReservationResponse MapToResponse(Reservation entity)
        {
            var response = _mapper.Map<ReservationResponse>(entity);
            
            // Load navigation properties if not already loaded
            if (entity.Car != null)
            {
                response.CarModel = entity.Car.Model;
                response.CarLicensePlate = entity.Car.LicensePlate;
                
                if (entity.Car.Brand != null)
                {
                    response.CarBrandName = entity.Car.Brand.Name;
                }
                
                if (entity.Car.Color != null)
                {
                    response.CarColorName = entity.Car.Color.Name;
                    response.CarColorHexCode = entity.Car.Color.HexCode;
                }
                
                // Include car picture if IncludePictures is true (default is true)
                if (_currentSearch?.IncludePictures != false && entity.Car.Picture != null && entity.Car.Picture.Length > 0)
                {
                    response.CarPicture = Convert.ToBase64String(entity.Car.Picture);
                }
                
                if (entity.Car.User != null)
                {
                    response.UserFullName = $"{entity.Car.User.FirstName} {entity.Car.User.LastName}".Trim();
                    // Only include picture if IncludePictures is true (default is true)
                    if (_currentSearch?.IncludePictures != false)
                    {
                        response.UserPicture = entity.Car.User.Picture;
                    }
                }
            }

            if (entity.ParkingSpot != null)
            {
                response.ParkingSpotNumber = entity.ParkingSpot.ParkingNumber;
                
                if (entity.ParkingSpot.ParkingSpotType != null)
                {
                    response.ParkingSpotTypeName = entity.ParkingSpot.ParkingSpotType.Name;
                }
            }

            if (entity.ReservationType != null)
            {
                response.ReservationTypeName = entity.ReservationType.Name;
            }

            // Include QR code data
            response.QrCodeData = entity.QrCodeData;

            return response;
        }

        protected override async Task BeforeInsert(Reservation entity, ReservationUpsertRequest request)
        {
            // Validate that dates are provided
            if (!request.StartDate.HasValue || !request.EndDate.HasValue)
            {
                throw new InvalidOperationException("StartDate and EndDate are required for reservations.");
            }

            if (request.StartDate.Value >= request.EndDate.Value)
            {
                throw new InvalidOperationException("EndDate must be after StartDate.");
            }

            // Load related entities for price calculation
            var car = await _context.Cars
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == request.CarId);
            
            if (car == null)
            {
                throw new InvalidOperationException("Car not found.");
            }

            var parkingSpot = await _context.ParkingSpots
                .Include(ps => ps.ParkingSpotType)
                .FirstOrDefaultAsync(ps => ps.Id == request.ParkingSpotId);
            
            if (parkingSpot == null)
            {
                throw new InvalidOperationException("Parking spot not found.");
            }

            if (!parkingSpot.IsActive)
            {
                throw new InvalidOperationException("Parking spot is not active.");
            }

            var reservationType = await _context.ReservationTypes
                .FirstOrDefaultAsync(rt => rt.Id == request.ReservationTypeId);
            
            if (reservationType == null)
            {
                throw new InvalidOperationException("Reservation type not found.");
            }

            // Check for date conflicts
            await ValidateNoDateConflicts(request.ParkingSpotId, request.StartDate.Value, request.EndDate.Value, null);

            // Calculate final price
            entity.FinalPrice = CalculateFinalPrice(reservationType, parkingSpot.ParkingSpotType, request.StartDate.Value, request.EndDate.Value);
            entity.CreatedAt = DateTime.UtcNow;
        }

        public override async Task<ReservationResponse> CreateAsync(ReservationUpsertRequest request)
        {
            var entity = new Reservation();
            MapInsertToEntity(entity, request);
            _context.Reservations.Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Generate QR code data after reservation is saved (so we have the ID)
            entity.QrCodeData = GenerateQrCodeData(entity);
            await _context.SaveChangesAsync();
            
            // Send notification after successful creation
            await SendReservationNotificationAsync(entity.Id);
            
            return MapToResponse(entity);
        }

        private string GenerateQrCodeData(Reservation reservation)
        {
            // Generate a unique QR code string containing reservation information
            // Format: RESERVATION:{Id}:{CarId}:{ParkingSpotId}:{StartDate:yyyyMMddHHmm}:{EndDate:yyyyMMddHHmm}
            var startDateStr = reservation.StartDate?.ToString("yyyyMMddHHmm") ?? "";
            var endDateStr = reservation.EndDate?.ToString("yyyyMMddHHmm") ?? "";
            return $"RESERVATION:{reservation.Id}:{reservation.CarId}:{reservation.ParkingSpotId}:{startDateStr}:{endDateStr}";
        }

        protected override async Task BeforeUpdate(Reservation entity, ReservationUpsertRequest request)
        {
            // Validate that dates are provided
            if (!request.StartDate.HasValue || !request.EndDate.HasValue)
            {
                throw new InvalidOperationException("StartDate and EndDate are required for reservations.");
            }

            if (request.StartDate.Value >= request.EndDate.Value)
            {
                throw new InvalidOperationException("EndDate must be after StartDate.");
            }

            // Load related entities for price calculation
            var parkingSpot = await _context.ParkingSpots
                .Include(ps => ps.ParkingSpotType)
                .FirstOrDefaultAsync(ps => ps.Id == request.ParkingSpotId);
            
            if (parkingSpot == null)
            {
                throw new InvalidOperationException("Parking spot not found.");
            }

            if (!parkingSpot.IsActive)
            {
                throw new InvalidOperationException("Parking spot is not active.");
            }

            var reservationType = await _context.ReservationTypes
                .FirstOrDefaultAsync(rt => rt.Id == request.ReservationTypeId);
            
            if (reservationType == null)
            {
                throw new InvalidOperationException("Reservation type not found.");
            }

            // Check for date conflicts (excluding current reservation)
            await ValidateNoDateConflicts(request.ParkingSpotId, request.StartDate.Value, request.EndDate.Value, entity.Id);

            // Recalculate final price
            entity.FinalPrice = CalculateFinalPrice(reservationType, parkingSpot.ParkingSpotType, request.StartDate.Value, request.EndDate.Value);
        }


        private async Task ValidateNoDateConflicts(int parkingSpotId, DateTime startDate, DateTime endDate, int? excludeReservationId)
        {
            // Check for overlapping reservations on the same parking spot
            // Two reservations overlap if: start1 < end2 && start2 < end1
            var conflictingReservation = await _context.Reservations
                .Where(r => r.ParkingSpotId == parkingSpotId
                    && r.Id != excludeReservationId
                    && r.StartDate.HasValue
                    && r.EndDate.HasValue
                    && r.StartDate < endDate
                    && startDate < r.EndDate)
                .FirstOrDefaultAsync();

            if (conflictingReservation != null)
            {
                throw new InvalidOperationException($"The parking spot is already reserved for the selected dates. Conflict with reservation ID {conflictingReservation.Id}.");
            }
        }

        private decimal CalculateFinalPrice(ReservationType reservationType, ParkingSpotType parkingSpotType, DateTime startDate, DateTime endDate)
        {
            var basePrice = reservationType.Price;
            var multiplier = parkingSpotType.PriceMultiplier;

            // Calculate price based on reservation type
            switch (reservationType.Name.ToLower())
            {
                case "hourly":
                    // For hourly: number of hours * price * multiplier
                    var hours = (decimal)(endDate - startDate).TotalHours;
                    return hours * basePrice * multiplier;

                case "daily":
                    // For daily: price * multiplier (per day)
                    return basePrice * multiplier;

                case "monthly":
                    // For monthly: price * multiplier (per month)
                    return basePrice * multiplier;

                default:
                    throw new InvalidOperationException($"Unknown reservation type: {reservationType.Name}");
            }
        }

        private async Task SendReservationNotificationAsync(int reservationId)
        {
            try
            {
                var reservation = await _context.Reservations
                    .Include(r => r.Car)
                        .ThenInclude(c => c.User)
                    .Include(r => r.ParkingSpot)
                        .ThenInclude(ps => ps.ParkingZone)
                    .Include(r => r.ReservationType)
                    .FirstOrDefaultAsync(r => r.Id == reservationId);

                if (reservation == null || string.IsNullOrWhiteSpace(reservation.Car?.User?.Email))
                {
                    return;
                }

                var host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                var username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                var virtualhost = Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

                var notification = new ReservationNotification
                {
                    Reservation = new ReservationNotificationDto
                    {
                        UserEmail = reservation.Car.User.Email,
                        UserFullName = $"{reservation.Car.User.FirstName} {reservation.Car.User.LastName}".Trim(),
                        CarModel = reservation.Car.Model,
                        CarLicensePlate = reservation.Car.LicensePlate,
                        ParkingSpotNumber = reservation.ParkingSpot?.ParkingNumber ?? string.Empty,
                        ParkingZoneName = reservation.ParkingSpot?.ParkingZone?.Name ?? string.Empty,
                        ReservationTypeName = reservation.ReservationType?.Name ?? string.Empty,
                        StartDate = reservation.StartDate,
                        EndDate = reservation.EndDate,
                        FinalPrice = reservation.FinalPrice
                    }
                };

                await bus.PubSub.PublishAsync(notification);
            }
            catch (Exception ex)
            {
                // Log error but don't throw - notification failure shouldn't break reservation creation
                Console.WriteLine($"Failed to send reservation notification: {ex.Message}");
            }
        }
    }
}
