using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Services
{
    public class ParkingSpotService : BaseCRUDService<ParkingSpotResponse, ParkingSpotSearchObject, ParkingSpot, ParkingSpotUpsertRequest, ParkingSpotUpsertRequest>, IParkingSpotService
    {
        private static MLContext _mlContext = null;
        private static object _mlLock = new object();
        private static ITransformer? _model = null;

        public ParkingSpotService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
            if (_mlContext == null)
            {
                lock (_mlLock)
                {
                    if (_mlContext == null)
                    {
                        _mlContext = new MLContext();
                    }
                }
            }
        }

        protected override IQueryable<ParkingSpot> ApplyFilter(IQueryable<ParkingSpot> query, ParkingSpotSearchObject search)
        {
            query = query.Include(p => p.ParkingSpotType)
                         .Include(p => p.ParkingZone);

            if (!string.IsNullOrEmpty(search.ParkingNumber))
            {
                query = query.Where(x => x.ParkingNumber.Contains(search.ParkingNumber));
            }

            if (search.ParkingSpotTypeId.HasValue)
            {
                query = query.Where(x => x.ParkingSpotTypeId == search.ParkingSpotTypeId.Value);
            }

            if (search.ParkingZoneId.HasValue)
            {
                query = query.Where(x => x.ParkingZoneId == search.ParkingZoneId.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(x => x.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(x => x.ParkingNumber.Contains(search.FTS));
            }

            return query;
        }

        protected override ParkingSpotResponse MapToResponse(ParkingSpot entity)
        {
            var response = _mapper.Map<ParkingSpotResponse>(entity);
            if (entity.ParkingSpotType != null)
            {
                response.ParkingSpotTypeName = entity.ParkingSpotType.Name;
            }
            if (entity.ParkingZone != null)
            {
                response.ParkingZoneName = entity.ParkingZone.Name;
            }
            return response;
        }

        protected override async Task BeforeInsert(ParkingSpot entity, ParkingSpotUpsertRequest request)
        {
            if (!await _context.ParkingSpotTypes.AnyAsync(p => p.Id == request.ParkingSpotTypeId))
            {
                throw new InvalidOperationException("The specified parking spot type does not exist.");
            }

            if (!await _context.ParkingZones.AnyAsync(p => p.Id == request.ParkingZoneId))
            {
                throw new InvalidOperationException("The specified parking zone does not exist.");
            }
        }

        protected override async Task BeforeUpdate(ParkingSpot entity, ParkingSpotUpsertRequest request)
        {
            if (!await _context.ParkingSpotTypes.AnyAsync(p => p.Id == request.ParkingSpotTypeId))
            {
                throw new InvalidOperationException("The specified parking spot type does not exist.");
            }

            if (!await _context.ParkingZones.AnyAsync(p => p.Id == request.ParkingZoneId))
            {
                throw new InvalidOperationException("The specified parking zone does not exist.");
            }
        }

        public override async Task<ParkingSpotResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.ParkingSpots
                .Include(p => p.ParkingSpotType)
                .Include(p => p.ParkingZone)
                .FirstOrDefaultAsync(p => p.Id == id);
            
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public async Task<ParkingSpotResponse?> RecommendForUserInZone(int userId, int parkingZoneId, int? reservationTypeId = null, DateTime? startDate = null, DateTime? endDate = null)
        {
            if (_model == null)
            {
                // Fallback: recommend using heuristic approach
                return await RecommendHeuristic(userId, parkingZoneId, reservationTypeId, startDate, endDate);
            }

            var predictionEngine = _mlContext.Model.CreatePredictionEngine<FeedbackEntry, ParkingSpotScorePrediction>(_model);

            // Get spots user has used in this zone (via reservations through cars)
            var userReservations = await _context.Reservations
                .Include(r => r.Car)
                .Include(r => r.ParkingSpot)
                .Where(r => r.Car.UserId == userId && r.ParkingSpot.ParkingZoneId == parkingZoneId)
                .ToListAsync();
            
            var usedSpotIds = userReservations
                .Select(r => r.ParkingSpotId)
                .Distinct()
                .ToList();

            // Get spots user has reviewed positively (rating >= 4) in this zone
            var userReviews = await _context.Reviews
                .Where(r => r.UserId == userId && r.Rating >= 4)
                .Include(r => r.Reservation)
                .ThenInclude(res => res.ParkingSpot)
                .ToListAsync();
            
            var highlyRatedSpotIds = userReviews
                .Where(r => r.Reservation.ParkingSpot.ParkingZoneId == parkingZoneId)
                .Select(r => r.Reservation.ParkingSpotId)
                .Distinct()
                .ToList();

            // Get preferred spot types from user's past experiences
            var userReservationsForZone = await _context.Reservations
                .Include(r => r.Car)
                .Include(r => r.ParkingSpot)
                .Where(r => r.Car.UserId == userId && r.ParkingSpot.ParkingZoneId == parkingZoneId)
                .ToListAsync();
            
            var reviewedReservationIds = await _context.Reviews
                .Where(rev => rev.UserId == userId && rev.Rating >= 4)
                .Select(rev => rev.ReservationId)
                .ToListAsync();
            
            var reviewedReservations = await _context.Reservations
                .Include(r => r.ParkingSpot)
                .Where(r => reviewedReservationIds.Contains(r.Id) && r.ParkingSpot.ParkingZoneId == parkingZoneId)
                .ToListAsync();
            
            var preferredSpotTypeIds = userReservationsForZone
                .Union(reviewedReservations)
                .Select(r => r.ParkingSpot.ParkingSpotTypeId)
                .Distinct()
                .ToList();

            // Get candidate spots in the specified zone that user hasn't used
            var candidateSpots = await _context.ParkingSpots
                .Include(p => p.ParkingSpotType)
                .Include(p => p.ParkingZone)
                .Where(p => p.ParkingZoneId == parkingZoneId && p.IsActive && !usedSpotIds.Contains(p.Id))
                .ToListAsync();

            if (!candidateSpots.Any())
            {
                // If all spots have been used, include them but still prioritize preferred types
                candidateSpots = await _context.ParkingSpots
                    .Include(p => p.ParkingSpotType)
                    .Include(p => p.ParkingZone)
                    .Where(p => p.ParkingZoneId == parkingZoneId && p.IsActive)
                    .ToListAsync();
            }

            // Filter out spots with conflicts if dates are provided
            if (startDate.HasValue && endDate.HasValue)
            {
                var conflictedSpotIds = await GetConflictedSpotIds(candidateSpots.Select(p => p.Id).ToList(), startDate.Value, endDate.Value);
                candidateSpots = candidateSpots.Where(p => !conflictedSpotIds.Contains(p.Id)).ToList();
            }

            if (!candidateSpots.Any())
            {
                return await RecommendHeuristic(userId, parkingZoneId, reservationTypeId, startDate, endDate);
            }

            // Score all candidates
            var scored = candidateSpots
                .Select(ps => new
                {
                    ParkingSpot = ps,
                    MLScore = predictionEngine.Predict(new FeedbackEntry
                    {
                        UserId = (uint)userId,
                        ParkingSpotId = (uint)ps.Id
                    }).Score,
                    // Boost score if spot type is preferred
                    TypeBoost = preferredSpotTypeIds.Contains(ps.ParkingSpotTypeId) ? 0.5f : 0f,
                    // Boost score if spot was highly rated
                    RatingBoost = highlyRatedSpotIds.Contains(ps.Id) ? 0.3f : 0f
                })
                .Select(x => new
                {
                    x.ParkingSpot,
                    FinalScore = x.MLScore + x.TypeBoost + x.RatingBoost
                })
                .OrderByDescending(x => x.FinalScore)
                .First().ParkingSpot;

            return MapToResponse(scored);
        }

        private async Task<List<int>> GetConflictedSpotIds(List<int> spotIds, DateTime startDate, DateTime endDate)
        {
            var conflictedReservations = await _context.Reservations
                .Where(r => spotIds.Contains(r.ParkingSpotId) &&
                           r.StartDate.HasValue &&
                           r.EndDate.HasValue &&
                           r.StartDate < endDate &&
                           r.EndDate > startDate)
                .Select(r => r.ParkingSpotId)
                .Distinct()
                .ToListAsync();

            return conflictedReservations;
        }

        private async Task<ParkingSpotResponse?> RecommendHeuristic(int userId, int parkingZoneId, int? reservationTypeId = null, DateTime? startDate = null, DateTime? endDate = null)
        {
            // Get spots user has used in this zone
            var userReservations = await _context.Reservations
                .Include(r => r.Car)
                .Include(r => r.ParkingSpot)
                .Where(r => r.Car.UserId == userId && r.ParkingSpot.ParkingZoneId == parkingZoneId)
                .ToListAsync();
            
            var usedSpotIds = userReservations
                .Select(r => r.ParkingSpotId)
                .Distinct()
                .ToList();

            // Get highly rated spots (rating >= 4) from user's reviews in this zone
            var userReviews = await _context.Reviews
                .Where(r => r.UserId == userId && r.Rating >= 4)
                .Include(r => r.Reservation)
                .ThenInclude(res => res.ParkingSpot)
                .ToListAsync();
            
            var highlyRatedSpotIds = userReviews
                .Where(r => r.Reservation.ParkingSpot.ParkingZoneId == parkingZoneId)
                .Select(r => r.Reservation.ParkingSpotId)
                .Distinct()
                .ToList();

            // Get preferred spot types
            var userReservationsForZone = await _context.Reservations
                .Include(r => r.Car)
                .Include(r => r.ParkingSpot)
                .Where(r => r.Car.UserId == userId && r.ParkingSpot.ParkingZoneId == parkingZoneId)
                .ToListAsync();
            
            var reviewedReservationIds = await _context.Reviews
                .Where(rev => rev.UserId == userId && rev.Rating >= 4)
                .Select(rev => rev.ReservationId)
                .ToListAsync();
            
            var reviewedReservations = await _context.Reservations
                .Include(r => r.ParkingSpot)
                .Where(r => reviewedReservationIds.Contains(r.Id) && r.ParkingSpot.ParkingZoneId == parkingZoneId)
                .ToListAsync();
            
            var preferredSpotTypeIds = userReservationsForZone
                .Union(reviewedReservations)
                .Select(r => r.ParkingSpot.ParkingSpotTypeId)
                .Distinct()
                .ToList();

            // Find spots in preferred types that user hasn't used
            var candidateSpots = await _context.ParkingSpots
                .Include(p => p.ParkingSpotType)
                .Include(p => p.ParkingZone)
                .Where(p => p.ParkingZoneId == parkingZoneId && p.IsActive)
                .ToListAsync();

            // Filter out spots with conflicts if dates are provided
            if (startDate.HasValue && endDate.HasValue)
            {
                var conflictedSpotIds = await GetConflictedSpotIds(candidateSpots.Select(p => p.Id).ToList(), startDate.Value, endDate.Value);
                candidateSpots = candidateSpots.Where(p => !conflictedSpotIds.Contains(p.Id)).ToList();
            }

            if (!candidateSpots.Any())
            {
                return null;
            }

            // Prioritize new spots in preferred types
            var newSpots = candidateSpots
                .Where(p => !usedSpotIds.Contains(p.Id) && preferredSpotTypeIds.Contains(p.ParkingSpotTypeId))
                .ToList();

            ParkingSpot? recommendedSpot;

            if (newSpots.Any())
            {
                var random = new Random();
                recommendedSpot = newSpots[random.Next(newSpots.Count)];
            }
            else
            {
                // Fallback to any new spot, or highly rated spot
                var fallbackSpots = candidateSpots
                    .Where(p => !usedSpotIds.Contains(p.Id) || highlyRatedSpotIds.Contains(p.Id))
                    .ToList();

                if (fallbackSpots.Any())
                {
                    var random = new Random();
                    recommendedSpot = fallbackSpots[random.Next(fallbackSpots.Count)];
                }
                else
                {
                    var random = new Random();
                    recommendedSpot = candidateSpots[random.Next(candidateSpots.Count)];
                }
            }

            return MapToResponse(recommendedSpot);
        }

        // Train recommender using Matrix Factorization on (User, ParkingSpot) implicit feedback
        public static void TrainRecommenderAtStartup(IServiceProvider serviceProvider)
        {
            lock (_mlLock)
            {
                if (_mlContext == null)
                {
                    _mlContext = new MLContext();
                }
                using var scope = serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<MoSmartParkDbContext>();

                // Build implicit feedback dataset from reservations (users booking spots)
                var positiveEntries = db.Reservations
                    .Include(r => r.Car)
                    .Select(r => new FeedbackEntry
                    {
                        UserId = (uint)r.Car.UserId,
                        ParkingSpotId = (uint)r.ParkingSpotId,
                        Label = 1f
                    })
                    .ToList();

                // Add positive feedback from highly rated reviews
                var positiveReviewEntries = db.Reviews
                    .Where(r => r.Rating >= 4)
                    .Include(r => r.Reservation)
                    .Select(r => new FeedbackEntry
                    {
                        UserId = (uint)r.UserId,
                        ParkingSpotId = (uint)r.Reservation.ParkingSpotId,
                        Label = 1.5f // Higher weight for highly rated spots
                    })
                    .ToList();

                positiveEntries.AddRange(positiveReviewEntries);

                if (!positiveEntries.Any())
                {
                    _model = null;
                    return;
                }

                var trainData = _mlContext.Data.LoadFromEnumerable(positiveEntries);
                var options = new Microsoft.ML.Trainers.MatrixFactorizationTrainer.Options
                {
                    MatrixColumnIndexColumnName = nameof(FeedbackEntry.UserId),
                    MatrixRowIndexColumnName = nameof(FeedbackEntry.ParkingSpotId),
                    LabelColumnName = nameof(FeedbackEntry.Label),
                    LossFunction = Microsoft.ML.Trainers.MatrixFactorizationTrainer.LossFunctionType.SquareLossOneClass,
                    Alpha = 0.01,
                    Lambda = 0.025,
                    NumberOfIterations = 50,
                    C = 0.00001
                };

                var estimator = _mlContext.Recommendation().Trainers.MatrixFactorization(options);
                _model = estimator.Fit(trainData);
            }
        }

        private class FeedbackEntry
        {
            [KeyType(count: 100000)]
            public uint UserId { get; set; }
            [KeyType(count: 100000)]
            public uint ParkingSpotId { get; set; }
            public float Label { get; set; }
        }

        private class ParkingSpotScorePrediction
        {
            public float Score { get; set; }
        }
    }
}

