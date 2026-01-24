import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosmartpark_mobile/model/review.dart';
import 'package:mosmartpark_mobile/providers/review_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ReviewDetailsScreen extends StatefulWidget {
  final Review review;

  const ReviewDetailsScreen({
    super.key,
    required this.review,
  });

  @override
  State<ReviewDetailsScreen> createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends State<ReviewDetailsScreen> {
  late TextEditingController _commentController;
  late TextEditingController _ratingController;
  int _selectedRating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.review.comment ?? '');
    _selectedRating = widget.review.rating;
    _ratingController = TextEditingController(
      text: _selectedRating > 0 ? '$_selectedRating / 5' : '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _updateReview() async {
    if (_selectedRating == 0) {
      _showErrorSnackbar('Please select a rating');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reviewProvider = context.read<ReviewProvider>();
      final user = UserProvider.currentUser;
      
      if (user == null) {
        _showErrorSnackbar('User not found. Please login again.');
        return;
      }
      
      final requestData = {
        'userId': user.id,
        'rating': _selectedRating,
        'comment': _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        'reservationId': widget.review.reservationId,
      };
      
      if (widget.review.id == 0) {
        // Create new review - first check if reservation already has a review
        try {
          final existingReviews = await reviewProvider.get(
            filter: {
              'reservationId': widget.review.reservationId,
              'page': 0,
              'pageSize': 1,
              'includeTotalCount': false,
            },
          );
          
          if (existingReviews.items != null && existingReviews.items!.isNotEmpty) {
            if (mounted) {
              _showErrorSnackbar('This reservation already has a review. Please edit the existing review instead.');
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }
        } catch (e) {
          // If check fails, proceed anyway - backend will validate
        }
        
        // Create new review
        await reviewProvider.insert(requestData);
        
        if (mounted) {
          _showSuccessSnackbar('Review created successfully!');
          Navigator.pop(context);
        }
      } else {
        // Update existing review
        await reviewProvider.update(
          widget.review.id,
          requestData,
        );
        
        if (mounted) {
          _showSuccessSnackbar('Review updated successfully!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to save review: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B6F47),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.review.id == 0 ? "Create Review" : "Edit Review",
          style: const TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Reservation Info Card with Cover Image
              Container(
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
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: _buildCarImage(
                              widget.review.carPicture,
                              width: double.infinity,
                              height: 180,
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
                              '${widget.review.carBrandName ?? ''} ${widget.review.carModel ?? ''}'.trim(),
                              style: const TextStyle(
                                fontSize: 20,
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
                              if (widget.review.parkingSpotNumber != null)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B6F47).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF8B6F47).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.local_parking_rounded,
                                          size: 16,
                                          color: Color(0xFF8B6F47),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Spot ${widget.review.parkingSpotNumber}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8B6F47),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (widget.review.reservationStartDate != null) ...[
                                if (widget.review.parkingSpotNumber != null) const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            DateFormat('MMM dd, yyyy').format(widget.review.reservationStartDate!),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Rating
              TextFormField(
                readOnly: true,
                controller: _ratingController,
                decoration: InputDecoration(
                  labelText: 'Rating',
                  prefixIcon: const Icon(Icons.star),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              // Star Rating Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = index + 1;
                          _ratingController.text = '$_selectedRating / 5';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          index < _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              // Comment
              TextFormField(
                controller: _commentController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Comment',
                  hintText: 'Share your experience...',
                  prefixIcon: const Icon(Icons.comment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6F47),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF8B6F47).withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.review.id == 0 ? 'Create Review' : 'Update Review',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

