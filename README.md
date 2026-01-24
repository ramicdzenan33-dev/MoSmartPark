# MoSmartPark - Smart Parking Management System

MoSmartPark is an intelligent parking management platform designed to streamline parking reservations, spot management, and user interactions. Built with .NET Core backend services and Flutter cross-platform applications, the system offers seamless experiences for both administrators and end users.

## Architecture Overview

The solution consists of four main components:

```
MoSmartPark/
├── MoSmartPark.Model/          # Data transfer objects, requests, responses, search filters
├── MoSmartPark.Services/       # Business logic, database context, and entity services
├── MoSmartPark.Subscriber/     # RabbitMQ message consumer for email notifications
├── MoSmartPark.WebAPI/         # RESTful API endpoints and controllers
└── UI/
    ├── mosmartpark_desktop/    # Flutter desktop application for administrators
    └── mosmartpark_mobile/     # Flutter mobile application for end users
```

## Quick Start

### Test Credentials

Both applications come with pre-filled login credentials for quick testing:

#### Desktop Application (Administrator)
- **Username:** `desktop` *(pre-filled)*
- **Password:** `test` *(pre-filled)*
- **Access:** Full administrative privileges including business reports, user management, parking zone configuration, and reservation oversight.

#### Mobile Application (End User)
- **Username:** `user` *(pre-filled)*
- **Password:** `test` *(pre-filled)*
- **Access:** Standard user features including reservation booking, car management, parking spot selection, and reservation history.

### Email Notifications

The system sends reservation confirmation emails via RabbitMQ. For testing email notifications:

- **Test Email Account:** `mosmartparkreciever@gmail.com`
- **Password:** `mosmartpark2025`

**Note:** This email account is associated with the default `user` test account. When reservations are created for this user, notification emails will be delivered to this inbox.

## Configuration

### Environment Variables

`.env` file is in the root directory (`MoSmartPark/`) with the following variables:

#### RabbitMQ Configuration
```env
RABBITMQ__HOST=localhost
RABBITMQ__USERNAME=guest
RABBITMQ__PASSWORD=guest
RABBITMQ__VIRTUALHOST=/
```

#### SQL Server Configuration
```env
SQL__USER=sa
SQL__PASSWORD=YourSecurePassword
SQL__DATABASE=MoSmartParkDb
SQL__PID=Developer  # Optional: SQL Server product ID
```

#### Mobile App Stripe Configuration

The mobile application requires a `.env` file in `MoSmartPark/UI/mosmartpark_mobile/` directory with Stripe payment gateway credentials:

```env
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
```

**Note:** The `.env` file in the mobile app directory comes pre-filled with testing/demo Stripe keys for development purposes. Replace these with your actual Stripe test keys from your Stripe dashboard for payment processing.

### Docker Compose Setup

The project includes `docker-compose.yml` for easy deployment of all services:

- **SQL Server:** Port `1401` (mapped from container port `1433`)
- **RabbitMQ:** Ports `5672` (AMQP) and `15672` (Management UI)
- **WebAPI:** Port `5130`
- **Subscriber Service:** Port `7111`

To start all services:
```bash
docker-compose up --build
```

## Key Features

### For Administrators (Desktop App)
- **Business Analytics:** Revenue reports, reservation statistics, and occupancy metrics
- **Parking Management:** Create and manage parking zones, spots, and spot types
- **User Administration:** User account management, role assignment, and access control
- **Reservation Oversight:** Monitor all reservations across the system
- **Real-time Monitoring:** Live parking spot availability and status tracking

### For End Users (Mobile App)
- **Smart Reservation Booking:** Hourly, daily, and monthly reservation options
- **Vehicle Management:** Register and manage multiple vehicles with brands and colors
- **Parking Spot Selection:** Interactive map-based selection with spot type filtering
- **QR Code Integration:** Digital reservation tickets with QR codes
- **Reservation History:** Track past and upcoming reservations
- **Reviews & Ratings:** Submit feedback on parking experiences

## Notification System

The system implements an asynchronous notification architecture using RabbitMQ:

1. **Reservation Creation:** When a reservation is successfully created, `ReservationService` publishes a notification message to RabbitMQ
2. **Message Processing:** The `MoSmartPark.Subscriber` service consumes messages from the queue
3. **Email Delivery:** Subscriber service sends formatted email notifications to the user's registered email address

### Testing Notifications

To verify the notification flow:

1. Log in to the mobile app with the `user` account
2. Create a new parking reservation
3. Check the inbox for `mosmartparkreciever@gmail.com`
4. The notification email will contain reservation details including parking spot, dates, and pricing

## Technology Stack

- **Backend:** .NET 8.0, Entity Framework Core, SQL Server
- **Messaging:** RabbitMQ with EasyNetQ
- **API:** ASP.NET Core Web API with Basic Authentication
- **Frontend:** Flutter (Dart) for cross-platform mobile and desktop
- **Containerization:** Docker & Docker Compose
- **Database Migrations:** EF Core Migrations with data seeding

## Database Schema

The system manages the following core entities:

- **Users & Authentication:** User accounts with role-based access control
- **Parking Infrastructure:** Zones, spots, and spot types (Regular, Compact, Large, Electric, Disabled)
- **Reservations:** Time-based bookings with dynamic pricing
- **Vehicles:** Car registry with brands, models, colors, and license plates
- **Reviews:** User feedback and ratings for reservations
- **Business Intelligence:** Aggregated reporting data for analytics

## Development

### Prerequisites
- .NET 8.0 SDK
- Flutter SDK (latest stable)
- Docker Desktop (for containerized services)
- SQL Server (or use Docker container)
- Visual Studio / Visual Studio Code / Rider

### Running Locally

1. **Start Infrastructure:**
   ```bash
   docker-compose up -d mosmartpark-sql rabbitmq
   ```

2. **Configure Environment:**
   - Copy `.env.example` to `.env` and update values
   - Ensure SQL Server and RabbitMQ are accessible

3. **Run WebAPI:**
   - Navigate to `MoSmartPark.WebAPI/`
   - Execute `dotnet run`
   - API will be available at `https://localhost:5130`
   - Swagger UI: `https://localhost:5130/swagger`

4. **Run Subscriber Service:**
   - Navigate to `MoSmartPark.Subscriber/`
   - Execute `dotnet run`

5. **Run Flutter Applications:**
   ```bash
   # Desktop App
   cd UI/mosmartpark_desktop
   flutter run -d windows  # or macos, linux

   # Mobile App
   cd UI/mosmartpark_mobile
   flutter run
   ```

## License

See LICENSE file for details.
