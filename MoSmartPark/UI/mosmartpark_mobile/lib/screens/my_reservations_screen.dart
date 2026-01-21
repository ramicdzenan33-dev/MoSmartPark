import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:mosmartpark_mobile/providers/reservation_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/screens/reservation_details_screen.dart';
import 'package:intl/intl.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  late ReservationProvider reservationProvider;
  List<Reservation>? reservations;
  List<Reservation>? filteredReservations;
  bool isLoading = true;
  String? errorMessage;
  Timer? _timer;
  String _selectedFilter = 'All'; // All, Active, Completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reservationProvider = context.read<ReservationProvider>();
      await _loadReservations();
      // Start timer to check if reload is needed
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _checkAndReloadIfNeeded();
        }
      });
    });
  }

  void _checkAndReloadIfNeeded() {
    if (reservations == null) return;
    
    final now = DateTime.now();
    bool needsReload = false;
    
    for (var reservation in reservations!) {
      if (reservation.startDate == null || reservation.endDate == null) continue;
      
      // Check if reservation just started (within last 2 seconds)
      final startDiff = now.difference(reservation.startDate!);
      if (startDiff.inSeconds >= 0 && startDiff.inSeconds <= 2) {
        needsReload = true;
        break;
      }
      
      // Check if reservation just ended (within last 2 seconds)
      final endDiff = now.difference(reservation.endDate!);
      if (endDiff.inSeconds >= 0 && endDiff.inSeconds <= 2) {
        needsReload = true;
        break;
      }
    }
    
    if (needsReload) {
      _loadReservations();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadReservations() async {
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

      // Load all reservations for the user (including past ones)
      final result = await reservationProvider.get(filter: {
        'userId': user.id,
        'retrieveAll': true,
      });

      // Sort by startDate (most recent first)
      final allReservations = (result.items ?? []).toList();
      allReservations.sort((a, b) {
        if (a.startDate == null || b.startDate == null) return 0;
        return b.startDate!.compareTo(a.startDate!); // Descending order
      });

      setState(() {
        reservations = allReservations;
        _applyFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load reservations: ${e.toString()}';
      });
    }
  }

  Color _getStatusColor(Reservation reservation) {
    final now = DateTime.now();
    
    if (reservation.startDate == null || reservation.endDate == null) {
      return Colors.grey;
    }

    if (now.isBefore(reservation.startDate!)) {
      return Colors.blue; // Upcoming
    } else if (now.isAfter(reservation.startDate!) && now.isBefore(reservation.endDate!)) {
      return Colors.green; // Active
    } else {
      return Colors.grey; // Past
    }
  }

  String _getStatusText(Reservation reservation) {
    final now = DateTime.now();
    
    if (reservation.startDate == null || reservation.endDate == null) {
      return 'Unknown';
    }

    if (now.isBefore(reservation.startDate!)) {
      return 'Upcoming';
    } else if (now.isAfter(reservation.startDate!) && now.isBefore(reservation.endDate!)) {
      return 'Active';
    } else {
      return 'Completed';
    }
  }

  void _applyFilter() {
    if (reservations == null) {
      filteredReservations = null;
      return;
    }

    final now = DateTime.now();
    setState(() {
      switch (_selectedFilter) {
        case 'Active':
          filteredReservations = reservations!.where((reservation) {
            if (reservation.startDate == null || reservation.endDate == null) return false;
            return now.isAfter(reservation.startDate!) && now.isBefore(reservation.endDate!);
          }).toList();
          break;
        case 'Completed':
          filteredReservations = reservations!.where((reservation) {
            if (reservation.endDate == null) return false;
            return now.isAfter(reservation.endDate!);
          }).toList();
          break;
        case 'Upcoming':
          filteredReservations = reservations!.where((reservation) {
            if (reservation.startDate == null) return false;
            return now.isBefore(reservation.startDate!);
          }).toList();
          break;
        default: // 'All'
          filteredReservations = reservations;
          break;
      }
    });
  }

  Widget _buildCarImage(String? pictureBase64, {double? width, double? height}) {
    final imgWidth = width ?? 120;
    final imgHeight = height ?? 120;
    
    if (pictureBase64 == null || pictureBase64.isEmpty) {
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.directions_car_rounded,
          size: 50,
          color: Color(0xFF8B6F47),
        ),
      );
    }
    
    try {
      String sanitized = pictureBase64;
      if (pictureBase64.contains(',')) {
        sanitized = pictureBase64.split(',').last;
      }
      sanitized = sanitized.trim();
      final bytes = base64Decode(sanitized);
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 50,
                color: Color(0xFF8B6F47),
              ),
            );
          },
        ),
      );
    } catch (e) {
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.directions_car_rounded,
          size: 50,
          color: Color(0xFF8B6F47),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8FAFC),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header with count and filters
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Reservations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${filteredReservations?.length ?? 0} ${(filteredReservations?.length ?? 0) == 1 ? 'reservation' : 'reservations'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedFilter == 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Upcoming', _selectedFilter == 'Upcoming'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', _selectedFilter == 'Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', _selectedFilter == 'Completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Reservations List
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
                            onPressed: _loadReservations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B6F47),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredReservations == null || filteredReservations!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No reservations found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFilter == 'All'
                                    ? 'Your reservations will appear here'
                                    : 'No $_selectedFilter.toLowerCase() reservations',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReservations,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              16,
                            ),
                            itemCount: filteredReservations!.length,
                            itemBuilder: (context, index) {
                              final reservation = filteredReservations![index];
                              final statusColor = _getStatusColor(reservation);
                              final statusText = _getStatusText(reservation);

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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReservationDetailsScreen(reservation: reservation),
                                        settings: const RouteSettings(name: 'ReservationDetailsScreen'),
                                      ),
                                    );
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
                                                reservation.carPicture,
                                                width: double.infinity,
                                                height: 160,
                                              ),
                                            ),
                                            // Gradient overlay
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
                                                      statusText == 'Active'
                                                          ? Icons.play_circle_filled_rounded
                                                          : statusText == 'Completed'
                                                              ? Icons.check_circle_rounded
                                                              : Icons.schedule_rounded,
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
                                                '${reservation.carBrandName ?? ''} ${reservation.carModel ?? ''}'.trim(),
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
                                            // Date and Time
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    reservation.startDate != null && reservation.endDate != null
                                                        ? '${DateFormat('MMM dd, HH:mm').format(reservation.startDate!)} - ${DateFormat('MMM dd, HH:mm').format(reservation.endDate!)}'
                                                        : 'N/A',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Details Row
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildInfoChip(
                                                    Icons.local_parking_rounded,
                                                    'Spot ${reservation.parkingSpotNumber ?? 'N/A'}',
                                                    const Color(0xFF8B6F47),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _buildInfoChip(
                                                    Icons.category_rounded,
                                                    reservation.reservationTypeName ?? 'N/A',
                                                    Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Price
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Total Price:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF8B6F47),
                                                        Color(0xFF6B5B3D),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '\$${reservation.finalPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          _applyFilter();
        });
      },
      selectedColor: const Color(0xFF8B6F47),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF8B6F47) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
    );
  }
}
