namespace MoSmartPark.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? ReservationId { get; set; }
        public int? Rating { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
        public string? UserFullName { get; set; }
        public bool IncludePictures { get; set; } = true; // Default to true to include pictures
    }
}
