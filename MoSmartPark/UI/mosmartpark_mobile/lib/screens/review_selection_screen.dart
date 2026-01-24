import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:mosmartpark_mobile/model/review.dart';
import 'package:mosmartpark_mobile/providers/reservation_provider.dart';
import 'package:mosmartpark_mobile/providers/review_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/screens/review_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ReviewSelectionScreen extends StatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  State<ReviewSelectionScreen> createState() => _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends State<ReviewSelectionScreen> {
  List<Reservation> _reservations = [];
  List<Reservation> _unreviewedReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (UserProvider.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reservationProvider = context.read<ReservationProvider>();
      final reviewProvider = context.read<ReviewProvider>();

      // Load reservations for current user
      final reservationsResult = await reservationProvider.get(
        filter: {
          'userId': UserProvider.currentUser!.id,
          'retrieveAll': true,
        },
      );

      // Load user's reviews to check which reservations they've already reviewed
      final userReviewsResult = await reviewProvider.get(
        filter: {
          'userId': UserProvider.currentUser!.id,
          'retrieveAll': true,
        },
      );

      if (mounted) {
        setState(() {
          _reservations = reservationsResult.items ?? [];
          
          // Filter: Remove reservations that the user has already reviewed
          final reviewedReservationIds = (userReviewsResult.items ?? [])
              .map((r) => r.reservationId)
              .toSet();
          
          _unreviewedReservations = _reservations
              .where((reservation) => !reviewedReservationIds.contains(reservation.id))
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createReviewForReservation(Reservation reservation) async {
    // Double-check that this reservation doesn't already have a review from this user
    try {
      final reviewProvider = context.read<ReviewProvider>();
      final existingReviews = await reviewProvider.get(
        filter: {
          'reservationId': reservation.id,
          'userId': UserProvider.currentUser!.id,
          'page': 0,
          'pageSize': 1,
          'includeTotalCount': false,
        },
      );
      
      if (existingReviews.items != null && existingReviews.items!.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text("This reservation already has a review. Please edit the existing review instead."),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          // Reload data to refresh the list
          await _loadData();
        }
        return;
      }
    } catch (e) {
      // If check fails, proceed anyway - backend will validate
    }

    // Create a new review object for this reservation
    final newReview = Review(
      id: 0,
      rating: 0,
      comment: null,
      createdAt: DateTime.now(),
      userId: UserProvider.currentUser!.id,
      reservationId: reservation.id,
      carBrandName: reservation.carBrandName,
      carModel: reservation.carModel,
      carLicensePlate: reservation.carLicensePlate,
      carPicture: reservation.carPicture,
      parkingSpotNumber: reservation.parkingSpotNumber,
      reservationTypeName: reservation.reservationTypeName,
      reservationStartDate: reservation.startDate,
      reservationEndDate: reservation.endDate,
      reservationFinalPrice: reservation.finalPrice,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDetailsScreen(review: newReview),
        settings: const RouteSettings(name: 'ReviewDetailsScreen'),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildCarImage(String? pictureBase64, {double? width, double? height}) {
    final imgWidth = width ?? 160;
    final imgHeight = height ?? 160;
    
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
        ),
        child: const Icon(
          Icons.directions_car_rounded,
          size: 50,
          color: Color(0xFF8B6F47),
        ),
      );
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Select Reservation to Review",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6B5B3D),
                const Color(0xFF8B6F47),
                const Color(0xFFA0826D),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B6F47)),
                    ),
                  )
                : _unreviewedReservations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF8B6F47),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _unreviewedReservations.length,
                          itemBuilder: (context, index) {
                            final reservation = _unreviewedReservations[index];
                            return _buildReservationCard(reservation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'All reservations reviewed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve reviewed all your parking reservations!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
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
        onTap: () => _createReviewForReservation(reservation),
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
                          Icons.calendar_today_rounded,
                          reservation.startDate != null
                              ? DateFormat('MMM dd').format(reservation.startDate!)
                              : 'N/A',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tap to Review Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tap to Review',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );
  }
}

