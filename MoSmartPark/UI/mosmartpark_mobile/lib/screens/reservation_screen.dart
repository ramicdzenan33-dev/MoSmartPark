import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mosmartpark_mobile/providers/car_provider.dart';
import 'package:mosmartpark_mobile/providers/reservation_type_provider.dart';
import 'package:mosmartpark_mobile/providers/parking_zone_provider.dart';
import 'package:mosmartpark_mobile/providers/parking_spot_provider.dart';
import 'package:mosmartpark_mobile/providers/parking_spot_type_provider.dart';
import 'package:mosmartpark_mobile/providers/reservation_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/model/car.dart';
import 'package:mosmartpark_mobile/model/reservation_type.dart';
import 'package:mosmartpark_mobile/model/parking_zone.dart';
import 'package:mosmartpark_mobile/model/parking_spot.dart';
import 'package:mosmartpark_mobile/model/parking_spot_type.dart';
import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:mosmartpark_mobile/screens/stripe_payment_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late CarProvider carProvider;
  late ReservationTypeProvider reservationTypeProvider;
  late ParkingZoneProvider parkingZoneProvider;
  late ParkingSpotProvider parkingSpotProvider;
  late ParkingSpotTypeProvider parkingSpotTypeProvider;
  late ReservationProvider reservationProvider;

  List<Car> cars = [];
  List<ReservationType> reservationTypes = [];
  List<ParkingZone> zones = [];
  List<ParkingSpot> spots = [];
  List<ParkingSpotType> spotTypes = [];
  Map<int, List<Reservation>> spotReservationsMap = {};
  Map<int, ParkingSpotType> spotTypesMap = {};

  Car? selectedCar;
  ReservationType? selectedReservationType;
  ParkingZone? selectedZone;
  ParkingSpot? selectedSpot;
  DateTime? selectedStartDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  DateTime? calculatedEndDate;

  bool isLoading = true;
  bool isCheckingConflicts = false;
  String? errorMessage;
  double? calculatedPrice;
  int? recommendedSpotId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      carProvider = context.read<CarProvider>();
      reservationTypeProvider = context.read<ReservationTypeProvider>();
      parkingZoneProvider = context.read<ParkingZoneProvider>();
      parkingSpotProvider = context.read<ParkingSpotProvider>();
      parkingSpotTypeProvider = context.read<ParkingSpotTypeProvider>();
      reservationProvider = context.read<ReservationProvider>();
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = UserProvider.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Load user's cars
      final carsResult = await carProvider.get(filter: {
        "userId": user.id,
        "pageSize": 1000,
      });

      // Load reservation types
      final typesResult = await reservationTypeProvider.get(filter: {
        "pageSize": 1000,
      });

      // Load parking zones
      final zonesResult = await parkingZoneProvider.get(filter: {
        "isActive": true,
        "pageSize": 1000,
      });

      // Load parking spot types
      final spotTypesResult = await parkingSpotTypeProvider.get(filter: {
        "pageSize": 1000,
      });

      // Load parking spots
      final spotsResult = await parkingSpotProvider.get(filter: {
        "pageSize": 1000,
      });

      setState(() {
        cars = carsResult.items ?? [];
        reservationTypes = typesResult.items ?? [];
        zones = zonesResult.items ?? [];
        spots = spotsResult.items ?? [];
        spotTypes = spotTypesResult.items ?? [];
        spotTypesMap = {for (var type in spotTypes) type.id: type};

        if (zones.isNotEmpty && selectedZone == null) {
          selectedZone = zones.first;
        }

        isLoading = false;
      });

      if (selectedZone != null) {
        await _loadReservationsForZone(selectedZone!);
        // Only load recommendation if we have reservation type and dates
        if (selectedReservationType != null && selectedStartDate != null && calculatedEndDate != null) {
          await _loadRecommendation(selectedZone!.id);
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadReservationsForZone(ParkingZone zone) async {
    try {
      // Load reservations for the selected zone and date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 365));

      final reservationsResult = await reservationProvider.get(filter: {
        "startDateTo": endOfDay.toIso8601String(),
        "endDateFrom": startOfDay.toIso8601String(),
        "pageSize": 1000,
        "includePictures": false,
      });

      Map<int, List<Reservation>> spotReservations = {};
      for (var reservation in reservationsResult.items ?? []) {
        final spot = spots.firstWhere(
          (s) => s.id == reservation.parkingSpotId,
          orElse: () => ParkingSpot(id: -1, parkingNumber: '', parkingSpotTypeId: 0, parkingZoneId: 0),
        );

        if (spot.id != -1 && spot.parkingZoneId == zone.id) {
          if (!spotReservations.containsKey(reservation.parkingSpotId)) {
            spotReservations[reservation.parkingSpotId] = [];
          }
          spotReservations[reservation.parkingSpotId]!.add(reservation);
        }
      }

      setState(() {
        spotReservationsMap = spotReservations;
      });

      _checkConflicts();
    } catch (e) {
      // Silently fail - reservations are optional for display
      print("Error loading reservations: $e");
    }
  }

  Future<void> _loadRecommendation(int parkingZoneId) async {
    try {
      final user = UserProvider.currentUser;
      if (user == null) return;

      // Only load recommendation if we have the necessary info
      if (selectedReservationType == null || selectedStartDate == null || calculatedEndDate == null) {
        // Clear recommendation if we don't have enough info
        setState(() {
          recommendedSpotId = null;
        });
        return;
      }

      final recommendation = await parkingSpotProvider.getRecommendation(
        user.id,
        parkingZoneId,
        reservationTypeId: selectedReservationType!.id,
        startDate: selectedStartDate!,
        endDate: calculatedEndDate!,
      );
      
      setState(() {
        recommendedSpotId = recommendation?.id;
      });
    } catch (e) {
      // Silently fail - recommendations are optional
      print("Error loading recommendation: $e");
    }
  }

  void _checkConflicts() {
    if (selectedSpot == null || selectedStartDate == null) {
      setState(() {
        isCheckingConflicts = false;
      });
      return;
    }

    setState(() {
      isCheckingConflicts = true;
    });

    // Check for conflicts with existing reservations
    final spotReservations = spotReservationsMap[selectedSpot!.id] ?? [];
    bool hasConflict = false;

    for (var reservation in spotReservations) {
      if (reservation.startDate != null && reservation.endDate != null &&
          selectedStartDate != null && calculatedEndDate != null) {
        // Check overlap: start1 < end2 && start2 < end1
        if (selectedStartDate!.isBefore(reservation.endDate!) &&
            reservation.startDate!.isBefore(calculatedEndDate!)) {
          hasConflict = true;
          break;
        }
      }
    }

    setState(() {
      isCheckingConflicts = false;
      if (hasConflict) {
        errorMessage = "Selected time conflicts with an existing reservation";
      } else {
        errorMessage = null;
      }
    });
  }

  void _calculateEndDate() {
    if (selectedStartDate == null || selectedReservationType == null) {
      setState(() {
        calculatedEndDate = null;
      });
      return;
    }

    DateTime endDate;
    switch (selectedReservationType!.name.toLowerCase()) {
      case "monthly":
        endDate = DateTime(
          selectedStartDate!.year,
          selectedStartDate!.month + 1,
          selectedStartDate!.day,
          selectedStartDate!.hour,
          selectedStartDate!.minute,
        );
        break;
      case "daily":
        // Daily reservation lasts 24 hours from start time
        endDate = selectedStartDate!.add(const Duration(hours: 24));
        break;
      case "hourly":
        if (selectedStartTime != null && selectedEndTime != null) {
          endDate = DateTime(
            selectedStartDate!.year,
            selectedStartDate!.month,
            selectedStartDate!.day,
            selectedEndTime!.hour,
            selectedEndTime!.minute,
          );
        } else {
          endDate = selectedStartDate!.add(const Duration(hours: 1));
        }
        break;
      default:
        endDate = selectedStartDate!.add(const Duration(hours: 1));
    }

    setState(() {
      calculatedEndDate = endDate;
    });

    _calculatePrice();
    _checkConflicts();
    
    // Reload recommendation with new dates if we have all required info
    if (selectedZone != null && selectedReservationType != null && selectedStartDate != null && calculatedEndDate != null) {
      _loadRecommendation(selectedZone!.id);
    }
  }

  void _calculatePrice() {
    if (selectedReservationType == null ||
        selectedSpot == null ||
        selectedStartDate == null ||
        calculatedEndDate == null) {
      setState(() {
        calculatedPrice = null;
      });
      return;
    }

    final spotType = spotTypesMap[selectedSpot!.parkingSpotTypeId];
    if (spotType == null) {
      setState(() {
        calculatedPrice = null;
      });
      return;
    }

    double price;
    switch (selectedReservationType!.name.toLowerCase()) {
      case "hourly":
        final hours = calculatedEndDate!.difference(selectedStartDate!).inHours.toDouble();
        price = hours * selectedReservationType!.price * spotType.priceMultiplier;
        break;
      case "daily":
        price = selectedReservationType!.price * spotType.priceMultiplier;
        break;
      case "monthly":
        price = selectedReservationType!.price * spotType.priceMultiplier;
        break;
      default:
        price = 0.0;
    }

    setState(() {
      calculatedPrice = price;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked;
      });
      _selectStartTime();
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedStartTime = picked;
        selectedStartDate = DateTime(
          selectedStartDate?.year ?? DateTime.now().year,
          selectedStartDate?.month ?? DateTime.now().month,
          selectedStartDate?.day ?? DateTime.now().day,
          picked.hour,
          picked.minute,
        );
      });
      _calculateEndDate();
    }
  }

  Future<void> _selectEndTime() async {
    if (selectedReservationType?.name.toLowerCase() != "hourly") {
      return;
    }

    final now = TimeOfDay.now();
    final initialEndTime = selectedEndTime ?? TimeOfDay(
      hour: (now.hour + 1) % 24,
      minute: now.minute,
    );
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialEndTime,
    );

    if (picked != null) {
      setState(() {
        selectedEndTime = picked;
      });
      _calculateEndDate();
    }
  }

  Future<void> _handleCheckout() async {
    if (selectedCar == null ||
        selectedReservationType == null ||
        selectedSpot == null ||
        selectedStartDate == null ||
        calculatedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (calculatedPrice == null || calculatedPrice! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid price calculation"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Navigate to payment screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StripePaymentScreen(
            selectedCar: selectedCar!,
            selectedSpot: selectedSpot!,
            selectedReservationType: selectedReservationType!,
            startDate: selectedStartDate!,
            endDate: calculatedEndDate!,
            price: calculatedPrice!,
          ),
          settings: const RouteSettings(name: 'StripePaymentScreen'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error navigating to payment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    
    // Check if we're already inside a Scaffold (from MasterScreen)
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null) {
      // Already in a Scaffold, return content directly
      return content;
    }
    
    // Not in a Scaffold, wrap in one
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reservation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Car Selection
          _buildSectionTitle("Select Car"),
          _buildCarSelector(),
          const SizedBox(height: 24),

          // Reservation Type Selection
          _buildSectionTitle("Reservation Type"),
          _buildReservationTypeSelector(),
          const SizedBox(height: 24),

          // Date & Time Selection
          _buildSectionTitle("Date & Time"),
          _buildDateTimeSelector(),
          const SizedBox(height: 24),

          // Zone Selection
          _buildSectionTitle("Parking Zone"),
          _buildZoneSelector(),
          const SizedBox(height: 24),

          // Parking Spots
          _buildSectionTitle("Select Parking Spot"),
          _buildParkingSpotsGrid(),
          const SizedBox(height: 24),

          // Price Summary
          if (calculatedPrice != null) ...[
            _buildPriceSummary(),
            const SizedBox(height: 24),
          ],

          // Checkout Button
          _buildCheckoutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildCarSelector() {
    if (cars.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "No cars available. Please add a car first.",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<Car>(
        value: selectedCar,
        isExpanded: true,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        hint: const Text("Select a car"),
        items: cars.map((car) {
          return DropdownMenuItem<Car>(
            value: car,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (car.picture != null && car.picture!.isNotEmpty)
                  Builder(
                    builder: (context) {
                      try {
                        // Remove data URI prefix if present, otherwise use as-is (backend returns plain base64)
                        String sanitized = car.picture!;
                        if (car.picture!.contains(',')) {
                          sanitized = car.picture!.split(',').last;
                        }
                        sanitized = sanitized.trim();
                        final bytes = base64Decode(sanitized);
                        return Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: MemoryImage(bytes),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } catch (e) {
                        return Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.directions_car, size: 20),
                        );
                      }
                    },
                  ),
                Flexible(
                  child: Text(
                    "${car.brandName} ${car.model}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (Car? car) {
          setState(() {
            selectedCar = car;
          });
        },
      ),
    );
  }

  Widget _buildReservationTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<ReservationType>(
        value: selectedReservationType,
        isExpanded: true,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        hint: const Text("Select reservation type"),
        items: reservationTypes.map((type) {
          return DropdownMenuItem<ReservationType>(
            value: type,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "\$${type.price.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (ReservationType? type) {
          setState(() {
            selectedReservationType = type;
            selectedEndTime = null;
            calculatedEndDate = null;
            calculatedPrice = null;
            recommendedSpotId = null;
          });
          _calculateEndDate();
          
          // Reload recommendation with new reservation type
          if (selectedZone != null) {
            _loadRecommendation(selectedZone!.id);
          }
        },
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      children: [
        // Start Date
        InkWell(
          onTap: _selectStartDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: const Color(0xFF8B6F47)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Start Date & Time",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedStartDate != null
                            ? "${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year} ${selectedStartTime?.format(context) ?? ''}"
                            : "Select start date",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // End Time (only for hourly)
        if (selectedReservationType?.name.toLowerCase() == "hourly")
          InkWell(
            onTap: _selectEndTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: const Color(0xFF8B6F47)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "End Time",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedEndTime != null
                              ? selectedEndTime!.format(context)
                              : "Select end time",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),

        // Calculated End Date Display
        if (calculatedEndDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F47).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: const Color(0xFF8B6F47)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Reservation ends: ${calculatedEndDate!.day}/${calculatedEndDate!.month}/${calculatedEndDate!.year} ${calculatedEndDate!.hour.toString().padLeft(2, '0')}:${calculatedEndDate!.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF8B6F47),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Conflict Warning
        if (errorMessage != null && isCheckingConflicts == false)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<ParkingZone>(
        value: selectedZone,
        isExpanded: true,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        hint: const Text("Select parking zone"),
        items: zones.map((zone) {
          return DropdownMenuItem<ParkingZone>(
            value: zone,
            child: Text(
              zone.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
        onChanged: (ParkingZone? zone) async {
          setState(() {
            selectedZone = zone;
            selectedSpot = null;
            recommendedSpotId = null;
          });
          if (zone != null) {
            await _loadReservationsForZone(zone);
            // Only load recommendation if we have reservation type and dates
            if (selectedReservationType != null && selectedStartDate != null && calculatedEndDate != null) {
              await _loadRecommendation(zone.id);
            }
          }
        },
      ),
    );
  }

  Widget _buildParkingSpotsGrid() {
    if (selectedZone == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "Please select a parking zone first",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final zoneSpots = spots.where((s) => s.parkingZoneId == selectedZone!.id).toList();
    
    if (zoneSpots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "No parking spots available in this zone",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    // Group spots by row
    Map<String, List<ParkingSpot>> groupedSpots = {};
    for (var spot in zoneSpots) {
      if (spot.parkingNumber.isNotEmpty) {
        String rowLetter = spot.parkingNumber[0];
        if (!groupedSpots.containsKey(rowLetter)) {
          groupedSpots[rowLetter] = [];
        }
        groupedSpots[rowLetter]!.add(spot);
      }
    }

    // Sort spots within each row
    for (var row in groupedSpots.keys) {
      groupedSpots[row]!.sort((a, b) {
        int aNum = int.tryParse(a.parkingNumber.substring(1)) ?? 0;
        int bNum = int.tryParse(b.parkingNumber.substring(1)) ?? 0;
        return aNum.compareTo(bNum);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _buildSpotTypeLegend(),
        const SizedBox(height: 16),

        // Parking spots grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: groupedSpots.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row label
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Row ${entry.key}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Spots in row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((spot) {
                        return _buildParkingSpotCard(spot);
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotTypeLegend() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: spotTypes.map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getSpotTypeColor(type.id, type.name),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        type.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFF8B6F47),
            size: 24,
          ),
          onPressed: _showReservationLegendPopup,
          tooltip: 'Reservation Guide',
        ),
      ],
    );
  }

  void _showReservationLegendPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: const Color(0xFF8B6F47),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Reservation Guide",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Spot Type Colors
                  _buildLegendSection(
                    "Spot Type Colors",
                    [
                      _buildLegendItem(
                        "Regular",
                        _getSpotTypeColor(1, "Regular"),
                        "Standard parking spot",
                      ),
                      _buildLegendItem(
                        "Compact",
                        _getSpotTypeColor(2, "Compact"),
                        "For smaller vehicles (0.8x price)",
                      ),
                      _buildLegendItem(
                        "Electric",
                        _getSpotTypeColor(4, "Electric"),
                        "With charging stations (1.3x price)",
                      ),
                      _buildLegendItem(
                        "Disabled",
                        _getSpotTypeColor(5, "Disabled"),
                        "Accessible parking (0.7x price)",
                      ),
                      _buildLegendItem(
                        "Large",
                        _getSpotTypeColor(3, "Large"),
                        "Spacious spots (1.5x price)",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Spot Status
                  _buildLegendSection(
                    "Spot Status",
                    [
                      _buildLegendItem(
                        "Available",
                        const Color(0xFFE2E8F0),
                        "Gray border - Spot is available for reservation",
                      ),
                      _buildLegendItem(
                        "Recommended",
                        const Color(0xFFD4AF37),
                        "Golden border with star - AI recommended based on your preferences",
                      ),
                      _buildLegendItem(
                        "Selected",
                        const Color(0xFF10B981), // green color
                        "Colored border - You selected this spot",
                      ),
                      _buildLegendItem(
                        "Conflict",
                        Colors.red,
                        "Red border with X - Time conflicts with existing reservation",
                      ),
                      _buildLegendItem(
                        "Disabled",
                        Colors.grey,
                        "Grayed out with block icon - Spot is inactive and cannot be reserved",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reservation Types
                  _buildLegendSection(
                    "Reservation Types",
                    [
                      _buildLegendTextItem(
                        "Hourly",
                        "You select both start and end time. Price = hours × base price × spot multiplier",
                      ),
                      _buildLegendTextItem(
                        "Daily",
                        "You select start time only. Reservation lasts 24 hours from start. Price = base price × spot multiplier",
                      ),
                      _buildLegendTextItem(
                        "Monthly",
                        "You select start date only. Reservation lasts 1 month from start. Price = base price × spot multiplier",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Conflict Detection
                  _buildLegendSection(
                    "Conflict Detection",
                    [
                      _buildLegendTextItem(
                        "Automatic Check",
                        "The system automatically checks if your selected time conflicts with existing reservations.",
                      ),
                      _buildLegendTextItem(
                        "Red Indicator",
                        "If a spot shows a red border with X, it means there's already a reservation during your selected time period.",
                      ),
                      _buildLegendTextItem(
                        "Price Calculation",
                        "Price is calculated based on reservation type, duration, and spot type multiplier. See price breakdown for details.",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Got it",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendTextItem(String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 12, top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B6F47),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingSpotCard(ParkingSpot spot) {
    final spotColor = _getSpotTypeColor(spot.parkingSpotTypeId, spot.parkingSpotTypeName);
    final isSelected = selectedSpot?.id == spot.id;
    final isConflicted = _isSpotConflicted(spot);
    final isDisabled = !spot.isActive;
    final isRecommended = recommendedSpotId == spot.id && !isSelected && !isConflicted && !isDisabled;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                selectedSpot = spot;
              });
              _calculatePrice();
              _checkConflicts();
            },
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected
                ? spotColor.withOpacity(0.2)
                : isDisabled
                    ? Colors.grey[100]
                    : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? spotColor
                  : isConflicted
                      ? Colors.red
                      : isRecommended
                          ? const Color(0xFFD4AF37) // Golden for recommended
                          : isDisabled
                              ? Colors.grey[400]!
                              : const Color(0xFFE2E8F0),
              width: isSelected ? 3 : isConflicted ? 3 : isRecommended ? 3 : 2,
              style: isDisabled ? BorderStyle.solid : BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? spotColor.withOpacity(0.3)
                    : isConflicted
                        ? Colors.red.withOpacity(0.2)
                        : isRecommended
                            ? const Color(0xFFD4AF37).withOpacity(0.4)
                            : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 8 : isConflicted ? 8 : isRecommended ? 10 : 4,
                spreadRadius: isRecommended ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Color indicator
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDisabled ? Colors.grey[400] : spotColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Recommended indicator
              if (isRecommended)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Conflict indicator
              if (isConflicted && !isDisabled)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Disabled indicator
              if (isDisabled)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Spot number
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      spot.parkingNumber.length > 1
                          ? spot.parkingNumber.substring(1)
                          : spot.parkingNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDisabled
                            ? Colors.grey[600]
                            : isSelected
                                ? spotColor
                                : const Color(0xFF1E293B),
                      ),
                    ),
                    // Strikethrough for disabled spots
                    if (isDisabled)
                      Positioned(
                        child: Container(
                          height: 2,
                          color: Colors.grey[600],
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSpotConflicted(ParkingSpot spot) {
    if (selectedStartDate == null || calculatedEndDate == null) {
      return false;
    }

    final spotReservations = spotReservationsMap[spot.id] ?? [];
    for (var reservation in spotReservations) {
      if (reservation.startDate != null && reservation.endDate != null) {
        if (selectedStartDate!.isBefore(reservation.endDate!) &&
            reservation.startDate!.isBefore(calculatedEndDate!)) {
          return true;
        }
      }
    }
    return false;
  }

  Color _getSpotTypeColor(int? spotTypeId, String? spotTypeName) {
    if (spotTypeId == null) {
      return const Color(0xFF6B7280);
    }

    String name = (spotTypeName ?? '').toLowerCase();

    if (name.contains('regular') || name.contains('standard') || name.contains('normal')) {
      return const Color(0xFF10B981); // Green
    }
    if (name.contains('compact')) {
      return const Color(0xFFEF4444); // Red
    }
    if (name.contains('electric')) {
      return const Color(0xFFF59E0B); // Orange
    }
    if (name.contains('disabled') || name.contains('handicap')) {
      return const Color(0xFF3B82F6); // Blue
    }
    if (name.contains('large')) {
      return const Color(0xFF8B5CF6); // Purple
    }

    int hash = spotTypeId % 5;
    switch (hash) {
      case 0:
        return const Color(0xFF10B981);
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildPriceSummary() {
    if (selectedReservationType == null || selectedSpot == null || calculatedPrice == null) {
      return const SizedBox.shrink();
    }

    final spotType = spotTypesMap[selectedSpot!.parkingSpotTypeId];
    if (spotType == null) {
      return const SizedBox.shrink();
    }

    String calculationDetails = "";
    if (selectedStartDate != null && calculatedEndDate != null) {
      switch (selectedReservationType!.name.toLowerCase()) {
        case "hourly":
          final hours = calculatedEndDate!.difference(selectedStartDate!).inHours.toDouble();
          calculationDetails = "${hours.toStringAsFixed(1)} hours × \$${selectedReservationType!.price.toStringAsFixed(2)} × ${spotType.priceMultiplier}x";
          break;
        case "daily":
          calculationDetails = "1 day × \$${selectedReservationType!.price.toStringAsFixed(2)} × ${spotType.priceMultiplier}x";
          break;
        case "monthly":
          calculationDetails = "1 month × \$${selectedReservationType!.price.toStringAsFixed(2)} × ${spotType.priceMultiplier}x";
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B6F47).withOpacity(0.1),
            const Color(0xFF8B6F47).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B6F47).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Breakdown
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: const Color(0xFF8B6F47),
              ),
              const SizedBox(width: 8),
              const Text(
                "Price Breakdown",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Reservation Type
          _buildPriceDetailRow(
            "Reservation Type",
            "${selectedReservationType!.name} (\$${selectedReservationType!.price.toStringAsFixed(2)})",
          ),
          const SizedBox(height: 8),
          
          // Spot Type
          _buildPriceDetailRow(
            "Spot Type",
            "${spotType.name} (${spotType.priceMultiplier}x multiplier)",
          ),
          const SizedBox(height: 8),
          
          // Calculation
          if (calculationDetails.isNotEmpty) ...[
            _buildPriceDetailRow(
              "Calculation",
              calculationDetails,
            ),
            const SizedBox(height: 12),
          ],
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFF8B6F47).withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          
          // Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Price:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                "\$${calculatedPrice!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B6F47),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    final canCheckout = selectedCar != null &&
        selectedReservationType != null &&
        selectedSpot != null &&
        selectedStartDate != null &&
        calculatedEndDate != null &&
        errorMessage == null &&
        calculatedPrice != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canCheckout ? _handleCheckout : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B6F47),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Text(
          "Checkout",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

