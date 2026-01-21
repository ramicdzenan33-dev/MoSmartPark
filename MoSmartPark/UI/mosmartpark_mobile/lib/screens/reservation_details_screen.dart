import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class ReservationDetailsScreen extends StatelessWidget {
  final Reservation reservation;

  const ReservationDetailsScreen({
    super.key,
    required this.reservation,
  });

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

  Color _getStatusColor() {
    final now = DateTime.now();
    
    if (reservation.startDate == null || reservation.endDate == null) {
      return Colors.grey;
    }

    if (now.isBefore(reservation.startDate!)) {
      return Colors.blue; // Upcoming
    } else if (now.isAfter(reservation.startDate!) && now.isBefore(reservation.endDate!)) {
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
    } else if (now.isAfter(reservation.startDate!) && now.isBefore(reservation.endDate!)) {
      return 'Active';
    } else {
      return 'Ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Parking Ticket',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF8B6F47),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
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
                            color: Colors.grey[200],
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
                                  '${reservation.carBrandName ?? ''} ${reservation.carModel ?? ''}'.trim(),
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
                        painter: _DashedLinePainter(),
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
                          if (reservation.qrCodeData != null && reservation.qrCodeData!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: reservation.qrCodeData!,
                                version: QrVersions.auto,
                                size: 140,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'QR Code not available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
                                    color: Colors.grey[700],
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
                        painter: _DashedLinePainter(),
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
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildModernInfoRow(
                                  Icons.calendar_today_rounded,
                                  'Start',
                                  reservation.startDate != null
                                      ? DateFormat('MMM dd, yyyy').format(reservation.startDate!)
                                      : 'N/A',
                                  reservation.startDate != null
                                      ? DateFormat('HH:mm').format(reservation.startDate!)
                                      : '',
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                _buildModernInfoRow(
                                  Icons.event_available_rounded,
                                  'End',
                                  reservation.endDate != null
                                      ? DateFormat('MMM dd, yyyy').format(reservation.endDate!)
                                      : 'N/A',
                                  reservation.endDate != null
                                      ? DateFormat('HH:mm').format(reservation.endDate!)
                                      : '',
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactInfo(
                                        Icons.local_parking_rounded,
                                        'Spot',
                                        '${reservation.parkingSpotNumber ?? 'N/A'}',
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey[300],
                                    ),
                                    Expanded(
                                      child: _buildCompactInfo(
                                        Icons.category_rounded,
                                        'Type',
                                        reservation.reservationTypeName ?? 'N/A',
                                      ),
                                    ),
                                    if (reservation.parkingSpotTypeName != null && reservation.parkingSpotTypeName!.isNotEmpty) ...[
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey[300],
                                      ),
                                      Expanded(
                                        child: _buildCompactInfoWithColor(
                                          reservation.parkingSpotTypeName!.toLowerCase().contains('electric')
                                              ? Icons.electric_car_rounded
                                              : reservation.parkingSpotTypeName!.toLowerCase().contains('handicap') || reservation.parkingSpotTypeName!.toLowerCase().contains('disabled')
                                                  ? Icons.accessible_rounded
                                                  : Icons.local_parking_rounded,
                                          'Spot Type',
                                          reservation.parkingSpotTypeName!,
                                          _getSpotTypeColor(null, reservation.parkingSpotTypeName),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                                colors: [
                                  Color(0xFF8B6F47),
                                  Color(0xFF6B5B3D),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B6F47).withOpacity(0.3),
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

  Widget _buildModernInfoRow(IconData icon, String label, String date, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B6F47).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF8B6F47),
          ),
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
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B6F47),
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

  Widget _buildCompactInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF8B6F47),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompactInfoWithColor(IconData icon, String label, String value, Color iconColor) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
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

// Custom painter for dashed line (ticket stub effect)
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
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
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, size.height / 2), 10, circlePaint);
    canvas.drawCircle(Offset(size.width, size.height / 2), 10, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

