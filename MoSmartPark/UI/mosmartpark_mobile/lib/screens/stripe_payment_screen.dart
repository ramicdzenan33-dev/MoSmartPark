import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mosmartpark_mobile/model/car.dart';
import 'package:mosmartpark_mobile/model/parking_spot.dart';
import 'package:mosmartpark_mobile/model/reservation_type.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';
import 'package:mosmartpark_mobile/providers/auth_provider.dart';
import 'package:mosmartpark_mobile/providers/reservation_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/layouts/master_screen.dart';
import 'package:mosmartpark_mobile/screens/home_screen.dart';
import 'package:intl/intl.dart';


class StripePaymentScreen extends StatefulWidget {
  final Car selectedCar;
  final ParkingSpot selectedSpot;
  final ReservationType selectedReservationType;
  final DateTime startDate;
  final DateTime endDate;
  final double price;

  const StripePaymentScreen({
    super.key,
    required this.selectedCar,
    required this.selectedSpot,
    required this.selectedReservationType,
    required this.startDate,
    required this.endDate,
    required this.price,
  });

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _paymentCompleted = false;
  int? _generatedReservationId;
  int? _stripePaymentId;

  // MoSmartPark color scheme
  static const Color primaryColor = Color(0xFF8B6F47);
  static const Color primaryDark = Color(0xFF6B5B3D);

  InputDecoration _commonDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF334155) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: (isDark ? Colors.grey[600]! : Colors.grey).withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: (isDark ? Colors.grey[600]! : Colors.grey).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : null,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A120B),
                      const Color(0xFF3C2A21),
                      const Color(0xFF5C4033),
                    ]
                  : [
                      const Color(0xFF6B5B3D),
                      primaryColor,
                      const Color(0xFFA0826D),
                    ],
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : _paymentCompleted
              ? _buildPaymentSuccessScreen(isDark)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildPaymentForm(context, isDark),
                ),
    );
  }

  Widget _buildPaymentSuccessScreen(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Success message
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : primaryColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.2),
                        primaryDark.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Successful!',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your parking reservation has been confirmed.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Reservation ID: ${_generatedReservationId ?? 'N/A'}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reservation details card
          _buildReservationDetailsCard(isDark),

          const SizedBox(height: 32),

          // Action buttons
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      primaryColor,
                      primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to home screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MasterScreen(
                            child: HomeScreen(),
                            title: 'Mo Smart Park',
                          ),
                          settings: const RouteSettings(name: 'MasterScreen'),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.home_rounded, size: 22),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Car', '${widget.selectedCar.brandName} ${widget.selectedCar.model}', isDark: isDark),
                const SizedBox(height: 12),
                _buildSummaryRow('Spot', widget.selectedSpot.parkingNumber, isDark: isDark),
                const SizedBox(height: 12),
                _buildSummaryRow('Type', widget.selectedReservationType.name, isDark: isDark),
                const SizedBox(height: 12),
                _buildSummaryRow('Start Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.startDate), isDark: isDark),
                const SizedBox(height: 12),
                _buildSummaryRow('End Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.endDate), isDark: isDark),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.grey[600] : null),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Total Amount',
                  '\$${widget.price.toStringAsFixed(2)}',
                  isTotal: true,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your parking spot is reserved. Show your ticket at the entrance to open the gate.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDark = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? (isDark ? Colors.white : const Color(0xFF1F2937)) : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? primaryColor : (isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(BuildContext context, bool isDark) {
    return FormBuilder(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountCard(),
          const SizedBox(height: 24),
          _buildReservationDetailsSection(isDark),
          const SizedBox(height: 24),
          _buildBillingSection(isDark),
          const SizedBox(height: 32),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryColor,
            primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '\$${widget.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Parking Reservation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationDetailsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Reservation Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Car', '${widget.selectedCar.brandName} ${widget.selectedCar.model}', isDark),
          const SizedBox(height: 12),
          _buildDetailRow('Parking Spot', widget.selectedSpot.parkingNumber, isDark),
          const SizedBox(height: 12),
          _buildDetailRow('Reservation Type', widget.selectedReservationType.name, isDark),
          const SizedBox(height: 12),
          _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.startDate), isDark),
          const SizedBox(height: 12),
          _buildDetailRow('End Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.endDate), isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Billing Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            'name',
            'Full Name',
            initialValue: _getUserFullName(),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'address',
            'Address',
            initialValue: '123 Main Street',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'city',
                  'City',
                  initialValue: 'New York',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('state', 'State', initialValue: 'NY', isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'country',
                  'Country',
                  initialValue: 'United States',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'pincode',
                  'ZIP Code',
                  keyboardType: TextInputType.number,
                  isNumeric: true,
                  initialValue: '10001',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUserFullName() {
    final user = UserProvider.currentUser;
    if (user != null) {
      return '${user.firstName} ${user.lastName}';
    }
    return 'John Doe';
  }

  Widget _buildTextField(
    String name,
    String labelText, {
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
    String? initialValue,
    bool isDark = false,
  }) {
    return FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      decoration: _commonDecoration(isDark).copyWith(
        labelText: labelText,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      validator: isNumeric
          ? FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'This field is required.',
              ),
              FormBuilderValidators.numeric(
                errorText: 'This field must be numeric',
              ),
            ])
          : FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'This field is required.',
              ),
            ]),
      keyboardType: keyboardType,
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            primaryColor,
            primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.lock_outline_rounded, size: 22),
          label: const Text(
            "Proceed to Payment",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            if (formKey.currentState?.saveAndValidate() ?? false) {
              final formData = formKey.currentState?.value;

              try {
                await _processStripePayment(formData!);
              } catch (e) {
                _showErrorSnackbar('Payment failed: ${e.toString()}');
              }
            }
          },
        ),
      ),
    );
  }

  // Helper to build auth headers for backend API calls
  Map<String, String> _createApiHeaders() {
    final username = AuthProvider.username ?? "";
    final password = AuthProvider.password ?? "";
    final basicAuth = "Basic ${base64Encode(utf8.encode('$username:$password'))}";
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  // Creates a PaymentIntent via the backend API (server-side Stripe integration)
  Future<Map<String, dynamic>> _createPaymentIntent({
    required String name,
    required String email,
    required String address,
    required String pin,
    required String city,
    required String state,
    required String country,
  }) async {
    final baseUrl = BaseProvider.baseUrl;
    final headers = _createApiHeaders();

    final response = await http.post(
      Uri.parse('${baseUrl}StripePayment/create-payment-intent'),
      headers: headers,
      body: jsonEncode({
        'amount': widget.price,
        'currency': 'USD',
        'customerName': name,
        'customerEmail': email,
        'billingAddress': address,
        'billingCity': city,
        'billingState': state,
        'billingCountry': country,
        'billingZipCode': pin,
      }),
    );

    if (response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to create payment intent');
    }
  }

  // Initializes Stripe payment sheet with data from the backend
  Future<void> _initPaymentSheet(Map<String, dynamic> formData) async {
    final data = await _createPaymentIntent(
      name: formData['name'] ?? 'John Doe',
      email: UserProvider.currentUser?.email ?? '',
      address: formData['address'] ?? '',
      pin: formData['pincode'] ?? '',
      city: formData['city'] ?? '',
      state: formData['state'] ?? '',
      country: formData['country'] ?? '',
    );

    // Store the backend payment ID for later confirmation
    _stripePaymentId = data['stripePaymentId'];

    await stripe.Stripe.instance.initPaymentSheet(
      paymentSheetParameters: stripe.SetupPaymentSheetParameters(
        customFlow: false,
        merchantDisplayName: 'Mo Smart Park',
        paymentIntentClientSecret: data['clientSecret'],
        customerEphemeralKeySecret: data['ephemeralKey'],
        customerId: data['customerId'],
        style: ThemeMode.light,
      ),
    );
  }

  // Confirms the payment on the backend after successful Stripe payment
  Future<void> _confirmPaymentOnBackend(int stripePaymentId, int reservationId) async {
    final baseUrl = BaseProvider.baseUrl;
    final headers = _createApiHeaders();

    final response = await http.put(
      Uri.parse('${baseUrl}StripePayment/$stripePaymentId/confirm'),
      headers: headers,
      body: jsonEncode({
        'reservationId': reservationId,
      }),
    );

    if (response.statusCode >= 300) {
      print('Warning: Failed to confirm payment on backend: ${response.body}');
    }
  }

  Future<void> _processStripePayment(Map<String, dynamic> formData) async {
    setState(() => _isLoading = true);

    try {
      // 1. Create PaymentIntent via backend (server-side)
      await _initPaymentSheet(formData);

      // 2. Present Stripe payment sheet to the user
      await stripe.Stripe.instance.presentPaymentSheet();

      // 3. Payment succeeded - create reservation
      final reservation = await _createReservation();
      final reservationId = reservation['id'] as int;

      // 4. Confirm payment on backend and link to reservation
      if (_stripePaymentId != null) {
        await _confirmPaymentOnBackend(_stripePaymentId!, reservationId);
      }

      _showSuccessSnackbar('Payment successful!');

      // Navigate to home screen after successful payment
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MasterScreen(
                child: HomeScreen(),
                title: 'Mo Smart Park',
              ),
              settings: const RouteSettings(name: 'MasterScreen'),
            ),
            (route) => route.isFirst,
          );
        }
      }
    } on stripe.StripeException catch (e) {
      setState(() => _isLoading = false);

      if (e.error.code == 'canceled') {
        _showInfoSnackbar('Payment was canceled');
      } else {
        _showErrorSnackbar('Payment failed: ${e.error.message ?? e.toString()}');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('canceled') || errorMessage.contains('user canceled')) {
        _showInfoSnackbar('Payment was canceled');
      } else {
        _showErrorSnackbar('Payment failed: ${e.toString()}');
      }
    }
  }

  Future<Map<String, dynamic>> _createReservation() async {
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);

    final request = {
      'carId': widget.selectedCar.id,
      'parkingSpotId': widget.selectedSpot.id,
      'reservationTypeId': widget.selectedReservationType.id,
      'startDate': widget.startDate.toIso8601String(),
      'endDate': widget.endDate.toIso8601String(),
    };

    final reservation = await reservationProvider.insert(request);

    return {
      'id': reservation.id,
    };
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
        backgroundColor: primaryColor,
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
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
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
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}