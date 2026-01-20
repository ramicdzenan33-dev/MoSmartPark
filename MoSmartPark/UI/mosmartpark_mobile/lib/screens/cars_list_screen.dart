import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosmartpark_mobile/model/car.dart';
import 'package:mosmartpark_mobile/providers/car_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/screens/cars_edit_screen.dart';
import 'package:provider/provider.dart';

class CarsListScreen extends StatefulWidget {
  const CarsListScreen({super.key});

  @override
  State<CarsListScreen> createState() => _CarsListScreenState();
}

class _CarsListScreenState extends State<CarsListScreen> {
  late CarProvider carProvider;
  List<Car>? cars;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      carProvider = context.read<CarProvider>();
      await _loadCars();
    });
  }

  Future<void> _loadCars() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = UserProvider.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User not logged in';
        });
        return;
      }

      // Filter cars by current user
      final result = await carProvider.get(filter: {
        'userId': user.id,
        'retrieveAll': true,
      });

      setState(() {
        cars = result.items ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load cars: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.98),
                Colors.white.withOpacity(0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delete Car",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to deactivate ${car.brandName} ${car.model} (${car.licensePlate})?",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.red.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      // Deactivate instead of delete
      var currentCar = await carProvider.getById(car.id);
      if (currentCar == null) {
        throw Exception('Car not found');
      }

      var request = {
        'brandId': currentCar.brandId,
        'colorId': currentCar.colorId,
        'userId': currentCar.userId,
        'model': currentCar.model,
        'licensePlate': currentCar.licensePlate,
        'yearOfManufacture': currentCar.yearOfManufacture,
        'isActive': false,
        'picture': currentCar.picture,
      };

      await carProvider.update(car.id, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car deactivated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await _loadCars();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildCarImage(String? pictureBase64, {double? width, double? height}) {
    final imgWidth = width ?? 160;
    final imgHeight = height ?? 160;
    
    if (pictureBase64 != null && pictureBase64.isNotEmpty) {
      try {
        // Remove data URI prefix if present, otherwise use as-is (backend returns plain base64)
        String sanitized = pictureBase64;
        if (pictureBase64.contains(',')) {
          sanitized = pictureBase64.split(',').last;
        }
        
        // Remove any whitespace
        sanitized = sanitized.trim();
        
        final bytes = base64Decode(sanitized);
        return Image.memory(
          bytes,
          width: imgWidth,
          height: imgHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: imgWidth,
              height: imgHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B6F47).withOpacity(0.1),
                    const Color(0xFF8B6F47).withOpacity(0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 50,
                color: Color(0xFF8B6F47),
              ),
            );
          },
        );
      } catch (_) {
        return Container(
          width: imgWidth,
          height: imgHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B6F47).withOpacity(0.1),
                const Color(0xFF8B6F47).withOpacity(0.05),
              ],
            ),
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            size: 50,
            color: Color(0xFF8B6F47),
          ),
        );
      }
    }
    return Container(
      width: imgWidth,
      height: imgHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B6F47).withOpacity(0.1),
            const Color(0xFF8B6F47).withOpacity(0.05),
          ],
        ),
      ),
      child: const Icon(
        Icons.directions_car_rounded,
        size: 50,
        color: Color(0xFF8B6F47),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Car Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CarsEditScreen(),
                  settings: const RouteSettings(name: 'CarsEditScreen'),
                ),
              );
              if (result == true) {
                _loadCars();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add New Car',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6F47),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF8B6F47).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        // Cars List
        Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadCars,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : cars == null || cars!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No cars found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first car to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCars,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: cars!.length,
                              itemBuilder: (context, index) {
                                final car = cars![index];
                                final statusColor = car.isActive ? Colors.green : Colors.red;
                                final statusText = car.isActive ? 'Active' : 'Inactive';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CarsEditScreen(car: car),
                                          settings: const RouteSettings(name: 'CarsEditScreen'),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadCars();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Car Image Cover
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 160,
                                                width: double.infinity,
                                                color: Colors.grey[200],
                                                child: _buildCarImage(
                                                  car.picture,
                                                  width: double.infinity,
                                                  height: 160,
                                                ),
                                              ),
                                              // Gradient overlay for better text readability
                                              Positioned.fill(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.black.withOpacity(0.3),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Status Badge Overlay
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.95),
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.2),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        car.isActive
                                                            ? Icons.check_circle_rounded
                                                            : Icons.cancel_rounded,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        statusText,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Car Name Overlay
                                              Positioned(
                                                bottom: 12,
                                                left: 12,
                                                right: 12,
                                                child: Text(
                                                  '${car.brandName} ${car.model}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black54,
                                                        offset: Offset(0, 1),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Content Section
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Details Row
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildInfoChip(
                                                      Icons.confirmation_number_rounded,
                                                      car.licensePlate,
                                                      const Color(0xFF8B6F47),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _buildInfoChip(
                                                      Icons.calendar_today_rounded,
                                                      '${car.yearOfManufacture}',
                                                      Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Color and Delete Row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                          color: _parseColor(car.colorHexCode),
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: Colors.grey[300]!,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        car.colorName,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded),
                                                    color: Colors.red,
                                                    onPressed: () => _deleteCar(car),
                                                    tooltip: 'Delete car',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
        ),
      ],
    );
  }
}

