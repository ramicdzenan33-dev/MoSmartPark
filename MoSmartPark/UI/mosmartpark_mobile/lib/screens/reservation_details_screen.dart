import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mosmartpark_mobile/providers/parking_spot_provider.dart';
import 'package:mosmartpark_mobile/model/parking_spot.dart';
import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailsScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  ParkingSpot? _parkingSpot;
  bool _isLoadingSpot = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParkingSpot();
    });
  }

  Future<void> _loadParkingSpot() async {
    try {
      final provider = context.read<ParkingSpotProvider>();
      final spot = await provider.getById(widget.reservation.parkingSpotId);
      if (mounted) {
        setState(() {
          _parkingSpot = spot;
          _isLoadingSpot = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSpot = false;
        });
      }
    }
  }

  Reservation get reservation => widget.reservation;

  Widget _buildCarImage(
    String? pictureBase64, {
    double? width,
    double? height,
  }) {
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

  Color _getStatusColor() {
    final now = DateTime.now();

    if (reservation.startDate == null || reservation.endDate == null) {
      return Colors.grey;
    }

    if (now.isBefore(reservation.startDate!)) {
      return Colors.blue; // Upcoming
    } else if (now.isAfter(reservation.startDate!) &&
        now.isBefore(reservation.endDate!)) {
      return Colors.green; // Active
    } else {
      return Colors.grey; // Ended
    }
  }

  String _getStatusText() {
    final now = DateTime.now();

    if (reservation.startDate == null || reservation.endDate == null) {
      return 'Unknown';
    }

    if (now.isBefore(reservation.startDate!)) {
      return 'Upcoming';
    } else if (now.isAfter(reservation.startDate!) &&
        now.isBefore(reservation.endDate!)) {
      return 'Active';
    } else {
      return 'Ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Parking Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDark
            ? const Color(0xFF2D1B0E)
            : const Color(0xFF8B6F47),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // Main Ticket Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket Header with Car Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey[200],
                            child: _buildCarImage(
                              reservation.carPicture,
                              width: double.infinity,
                              height: 220,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${reservation.carBrandName ?? ''} ${reservation.carModel ?? ''}'
                                      .trim(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 8,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_rounded,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      reservation.carLicensePlate ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 4,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Ticket Number - Top Left
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.confirmation_number_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '#${reservation.id}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Status Badge - Top Right
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
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
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    statusText,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Perforated Edge Effect (Ticket Stub Style)
                    Container(
                      height: 20,
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          dashColor: isDark
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                          circleColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                        ),
                        child: Container(),
                      ),
                    ),
                    // QR Code Section - Right after header (smaller, left-aligned)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // QR Code (smaller, left-aligned)
                          if (reservation.qrCodeData != null &&
                              reservation.qrCodeData!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: reservation.qrCodeData!,
                                version: QrVersions.auto,
                                size: 140,
                                backgroundColor: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 60,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'QR Code not available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 20),
                          // Explanatory text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 20,
                                      color: const Color(0xFF8B6F47),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'How it works',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF8B6F47),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'When you arrive at the entrance, show this ticket to the staff member. And the staff member will open the gate for you.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Perforated Edge Effect (Ticket Stub Style)
                    Container(
                      height: 20,
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          dashColor: isDark
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                          circleColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                        ),
                        child: Container(),
                      ),
                    ),
                    // Ticket Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 5, 24, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ticket Details Grid (smaller)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildModernInfoRow(
                                  context,
                                  Icons.calendar_today_rounded,
                                  'Start',
                                  reservation.startDate != null
                                      ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(reservation.startDate!)
                                      : 'N/A',
                                  reservation.startDate != null
                                      ? DateFormat(
                                          'HH:mm',
                                        ).format(reservation.startDate!)
                                      : '',
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                _buildModernInfoRow(
                                  context,
                                  Icons.event_available_rounded,
                                  'End',
                                  reservation.endDate != null
                                      ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(reservation.endDate!)
                                      : 'N/A',
                                  reservation.endDate != null
                                      ? DateFormat(
                                          'HH:mm',
                                        ).format(reservation.endDate!)
                                      : '',
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactInfo(
                                        context,
                                        Icons.local_parking_rounded,
                                        'Spot',
                                        '${reservation.parkingSpotNumber ?? 'N/A'}',
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[300],
                                    ),
                                    Expanded(
                                      child: _buildCompactInfo(
                                        context,
                                        Icons.category_rounded,
                                        'Type',
                                        reservation.reservationTypeName ??
                                            'N/A',
                                      ),
                                    ),
                                    if (reservation.parkingSpotTypeName !=
                                            null &&
                                        reservation
                                            .parkingSpotTypeName!
                                            .isNotEmpty) ...[
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.grey[300],
                                      ),
                                      Expanded(
                                        child: _buildCompactInfoWithColor(
                                          context,
                                          reservation.parkingSpotTypeName!
                                                  .toLowerCase()
                                                  .contains('electric')
                                              ? Icons.electric_car_rounded
                                              : reservation.parkingSpotTypeName!
                                                        .toLowerCase()
                                                        .contains('handicap') ||
                                                    reservation
                                                        .parkingSpotTypeName!
                                                        .toLowerCase()
                                                        .contains('disabled')
                                              ? Icons.accessible_rounded
                                              : Icons.local_parking_rounded,
                                          'Spot Type',
                                          reservation.parkingSpotTypeName!,
                                          _getSpotTypeColor(
                                            null,
                                            reservation.parkingSpotTypeName,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSpotLocationMap(isDark),
                          const SizedBox(height: 20),
                          // Price Display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF8B6F47), Color(0xFF6B5B3D)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B6F47,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_rounded,
                                  size: 20,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    Text(
                                      'TOTAL PRICE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${reservation.finalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpotLocationMap(bool isDark) {
    if (_isLoadingSpot) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B6F47)),
        ),
      );
    }

    if (_parkingSpot == null ||
        _parkingSpot!.latitude == null ||
        _parkingSpot!.longitude == null) {
      return const SizedBox.shrink();
    }

    final spotLatLng = LatLng(
      _parkingSpot!.latitude!,
      _parkingSpot!.longitude!,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: spotLatLng,
                  initialZoom: 17.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mosmartpark.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: spotLatLng,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B6F47),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B6F47).withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_parking,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Spot info + navigate button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F47).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF8B6F47),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spot ${_parkingSpot!.parkingNumber}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Tap Navigate to open directions',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${_parkingSpot!.latitude},${_parkingSpot!.longitude}&travelmode=driving',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B6F47),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String date,
    String time,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B6F47).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF8B6F47)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B6F47),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8B6F47)),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompactInfoWithColor(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getSpotTypeColor(int? spotTypeId, String? spotTypeName) {
    if (spotTypeId == null && spotTypeName == null) {
      return const Color(0xFF6B7280);
    }

    String name = (spotTypeName ?? '').toLowerCase();

    if (name.contains('regular') ||
        name.contains('standard') ||
        name.contains('normal')) {
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

// Custom painter for dashed line (ticket stub effect)
class _DashedLinePainter extends CustomPainter {
  final Color dashColor;
  final Color circleColor;

  _DashedLinePainter({
    this.dashColor = const Color(0xFFE5E7EB),
    this.circleColor = const Color(0xFFF8FAFC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dashColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Add semicircles on sides for ticket stub effect
    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, size.height / 2), 10, circlePaint);
    canvas.drawCircle(Offset(size.width, size.height / 2), 10, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
