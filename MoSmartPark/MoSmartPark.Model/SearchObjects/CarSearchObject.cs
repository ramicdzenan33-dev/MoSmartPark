namespace MoSmartPark.Model.SearchObjects
{
    public class CarSearchObject : BaseSearchObject
    {
        public string? BrandModel { get; set; }
        public string? LicensePlate { get; set; }
        public int? BrandId { get; set; }
        public int? ColorId { get; set; }
        public int? UserId { get; set; }
        public int? YearOfManufacture { get; set; }
        public bool? IsActive { get; set; }
    }
}

