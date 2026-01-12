namespace MoSmartPark.Model.Responses
{
    public class BrandResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public byte[]? Logo { get; set; }
        public bool IsActive { get; set; }
    }
}

