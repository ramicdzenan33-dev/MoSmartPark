import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:mosmartpark_mobile/providers/reservation_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/screens/reservation_details_screen.dart';
import 'package:mosmartpark_mobile/screens/reservation_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ReservationProvider reservationProvider;
  List<Reservation>? reservations;
  bool isLoading = true;
  String? errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reservationProvider = context.read<ReservationProvider>();
      await _loadReservations();
      // Start timer to check if reload is needed (but don't rebuild UI)
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

      // Filter reservations by current user and retrieve all
      final result = await reservationProvider.get(filter: {
        'userId': user.id,
        'retrieveAll': true,
      });

      final now = DateTime.now();
      
      // Filter out past reservations (where endDate < now)
      final filteredReservations = (result.items ?? [])
          .where((reservation) {
            if (reservation.endDate == null) return false;
            return reservation.endDate!.isAfter(now);
          })
          .toList();

      // Sort by startDate (upcoming first, then active)
      filteredReservations.sort((a, b) {
        if (a.startDate == null || b.startDate == null) return 0;
        return a.startDate!.compareTo(b.startDate!);
      });

      setState(() {
        reservations = filteredReservations;
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
      return Colors.grey; // Ended (shouldn't happen)
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
      return 'Ended';
    }
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
      // Remove data URI prefix if present, otherwise use as-is (backend returns plain base64)
      String sanitized = pictureBase64;
      if (pictureBase64.contains(',')) {
        sanitized = pictureBase64.split(',').last;
      }
      
      // Remove any whitespace
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
          // Create Reservation Header
          _CreateReservationCard(),
          
          // Subtle header with count
          if (reservations != null && reservations!.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Reservations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reservations!.length} ${reservations!.length == 1 ? 'reservation' : 'reservations'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                  : reservations == null || reservations!.isEmpty
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
                                'No upcoming reservations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your upcoming reservations will appear here',
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
                              reservations != null && reservations!.isNotEmpty ? 8 : 16,
                              16,
                              16,
                            ),
                            itemCount: reservations!.length,
                            itemBuilder: (context, index) {
                              final reservation = reservations![index];
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
                                      RepaintBoundary(
                                        child: ClipRRect(
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
                                                      statusText == 'Active'
                                                          ? Icons.play_circle_filled_rounded
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
                                      ),
                                      // Content Section
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Time Remaining
                                            _CountdownWidget(
                                              reservation: reservation,
                                              statusColor: statusColor,
                                            ),
                                            const SizedBox(height: 16),
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
                                                if (reservation.parkingSpotTypeName != null && reservation.parkingSpotTypeName!.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _buildInfoChip(
                                                      reservation.parkingSpotTypeName!.toLowerCase().contains('electric')
                                                          ? Icons.electric_car_rounded
                                                          : reservation.parkingSpotTypeName!.toLowerCase().contains('handicap') || reservation.parkingSpotTypeName!.toLowerCase().contains('disabled')
                                                              ? Icons.accessible_rounded
                                                              : Icons.local_parking_rounded,
                                                      reservation.parkingSpotTypeName!,
                                                      _getSpotTypeColor(null, reservation.parkingSpotTypeName),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Date and Price Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today_rounded,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          reservation.startDate != null
                                                              ? DateFormat('MMM dd, HH:mm').format(reservation.startDate!)
                                                              : 'N/A',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey[700],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
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
                                            const SizedBox(height: 16),
                                            // View Ticket Button
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
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
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.qr_code_2_rounded,
                                                    size: 20,
                                                    color: const Color(0xFF8B6F47),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'View Ticket',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF8B6F47),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    size: 14,
                                                    color: const Color(0xFF8B6F47),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // Info about showing ticket at entrance
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 16,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Show your ticket at the entrance to open the gate',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
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

  Color _getSpotTypeColor(int? spotTypeId, String? spotTypeName) {
    if (spotTypeId == null && spotTypeName == null) {
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

    // Fallback: use hash of name if no match
    if (spotTypeName != null) {
      int hash = spotTypeName.hashCode % 5;
      switch (hash.abs()) {
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

    return const Color(0xFF6B7280); // Default gray
  }
}

// Separate widget for countdown that updates independently
class _CountdownWidget extends StatefulWidget {
  final Reservation reservation;
  final Color statusColor;

  const _CountdownWidget({
    required this.reservation,
    required this.statusColor,
  });

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start timer to update countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {}); // Only rebuild this widget, not the parent card
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    
    if (widget.reservation.startDate == null || widget.reservation.endDate == null) {
      return 'Invalid dates';
    }

    // If reservation hasn't started yet
    if (now.isBefore(widget.reservation.startDate!)) {
      final difference = widget.reservation.startDate!.difference(now);
      return _formatDuration(difference, isUpcoming: true);
    }
    // If reservation is active
    else if (now.isAfter(widget.reservation.startDate!) && now.isBefore(widget.reservation.endDate!)) {
      final difference = widget.reservation.endDate!.difference(now);
      return _formatDuration(difference, isUpcoming: false);
    }
    // Shouldn't happen since we filter these out, but just in case
    else {
      return 'Ended';
    }
  }

  String _formatDuration(Duration duration, {required bool isUpcoming}) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final prefix = isUpcoming ? 'Starts in: ' : 'Ends in: ';

    if (days > 0) {
      return '$prefix${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '$prefix${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '$prefix${minutes}m ${seconds}s';
    } else {
      return '$prefix${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = _getTimeRemaining();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: widget.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeRemaining,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Create Reservation Card Widget with modern design
class _CreateReservationCard extends StatefulWidget {
  const _CreateReservationCard();

  @override
  State<_CreateReservationCard> createState() => _CreateReservationCardState();
}

class _CreateReservationCardState extends State<_CreateReservationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _navigateToReservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReservationScreen(),
        settings: const RouteSettings(name: 'ReservationScreen'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: InkWell(
                  onTapDown: (_) => _scaleController.forward(),
                  onTapUp: (_) {
                    _scaleController.reverse();
                    _navigateToReservation();
                  },
                  onTapCancel: () => _scaleController.reverse(),
                  borderRadius: BorderRadius.circular(20),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                            Color(0xFFA855F7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutBack,
                            builder: (context, iconValue, child) {
                              final iconOpacity = iconValue.clamp(0.0, 1.0);
                              return Opacity(
                                opacity: iconOpacity,
                                child: Transform.scale(
                                  scale: iconValue,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, textValue, child) {
                                    final textOpacity = textValue.clamp(0.0, 1.0);
                                    return Opacity(
                                      opacity: textOpacity,
                                      child: Transform.translate(
                                        offset: Offset(10 * (1 - textValue), 0),
                                        child: const Text(
                                          'Parking Reservation',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, subValue, child) {
                                    final subOpacity = subValue.clamp(0.0, 1.0);
                                    return Opacity(
                                      opacity: subOpacity,
                                      child: Transform.translate(
                                        offset: Offset(10 * (1 - subValue), 0),
                                        child: Row(
                                          children: [
                                      
                                            Flexible(
                                              child: Text(
                                                'Reserve your parking spot',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Arrow icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutBack,
                            builder: (context, arrowValue, child) {
                              final arrowOpacity = arrowValue.clamp(0.0, 1.0);
                              return Opacity(
                                opacity: arrowOpacity,
                                child: Transform.scale(
                                  scale: arrowValue,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
