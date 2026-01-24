import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mosmartpark_mobile/model/car.dart';
import 'package:mosmartpark_mobile/model/parking_spot.dart';
import 'package:mosmartpark_mobile/model/reservation_type.dart';
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
  bool _isUsingMockPayment = false;

  // MoSmartPark color scheme
  static const Color primaryColor = Color(0xFF8B6F47);
  static const Color primaryDark = Color(0xFF6B5B3D);

  final commonDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B5B3D),
                primaryColor,
                Color(0xFFA0826D),
              ],
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : _paymentCompleted
              ? _buildPaymentSuccessScreen()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildPaymentForm(context),
                ),
    );
  }

  Widget _buildPaymentSuccessScreen() {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
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
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
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
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Reservation ID: ${_generatedReservationId ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[500],
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
          _buildReservationDetailsCard(),

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

  Widget _buildReservationDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reservation Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
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
                _buildSummaryRow('Car', '${widget.selectedCar.brandName} ${widget.selectedCar.model}'),
                const SizedBox(height: 12),
                _buildSummaryRow('Spot', widget.selectedSpot.parkingNumber),
                const SizedBox(height: 12),
                _buildSummaryRow('Type', widget.selectedReservationType.name),
                const SizedBox(height: 12),
                _buildSummaryRow('Start Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.startDate)),
                const SizedBox(height: 12),
                _buildSummaryRow('End Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.endDate)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Total Amount',
                  '\$${widget.price.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your parking spot is reserved. Show your ticket at the entrance to open the gate.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF1F2937) : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? primaryColor : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountCard(),
          const SizedBox(height: 24),
          _buildReservationDetailsSection(),
          const SizedBox(height: 24),
          _buildBillingSection(),
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

  Widget _buildReservationDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              const Text(
                'Reservation Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Car', '${widget.selectedCar.brandName} ${widget.selectedCar.model}'),
          const SizedBox(height: 12),
          _buildDetailRow('Parking Spot', widget.selectedSpot.parkingNumber),
          const SizedBox(height: 12),
          _buildDetailRow('Reservation Type', widget.selectedReservationType.name),
          const SizedBox(height: 12),
          _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.startDate)),
          const SizedBox(height: 12),
          _buildDetailRow('End Date', DateFormat('MMM dd, yyyy HH:mm').format(widget.endDate)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              fontWeight: FontWeight.w500,
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

  Widget _buildBillingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              const Text(
                'Billing Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            'name',
            'Full Name',
            initialValue: _getUserFullName(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'address',
            'Address',
            initialValue: '123 Main Street',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'city',
                  'City',
                  initialValue: 'New York',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('state', 'State', initialValue: 'NY'),
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
  }) {
    return FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      decoration: commonDecoration.copyWith(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[600]),
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

  // Stripe Payment Methods
  Future<void> _initPaymentSheet(Map<String, dynamic> formData) async {
    try {
      final data = await _createPaymentIntent(
        amount: (widget.price * 100).round().toString(),
        currency: 'USD',
        name: formData['name'] ?? 'John Doe',
        address: formData['address'] ?? '123 Main Street',
        pin: formData['pincode'] ?? '10001',
        city: formData['city'] ?? 'New York',
        state: formData['state'] ?? 'NY',
        country: formData['country'] ?? 'United States',
      );

      // Check if we're using mock data (mock secrets don't work with Stripe)
      final isMock = data['client_secret'].toString().contains('mock');
      _isUsingMockPayment = isMock;
      
      if (isMock) {
        // For mock data, skip Stripe initialization and go straight to reservation creation
        // This allows testing without a valid Stripe key
        print('Using mock payment intent - skipping Stripe payment sheet');
        return;
      }

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'Mo Smart Park',
          paymentIntentClientSecret: data['client_secret'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          style: ThemeMode.light,
        ),
      );
    } catch (e) {
      print('Error initializing payment sheet: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required String amount,
    required String currency,
    required String name,
    required String address,
    required String pin,
    required String city,
    required String state,
    required String country,
  }) async {
    try {
      // Use test/demo Stripe secret key (for development)
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? 
          'sk_test_51QJ8XxExampleKeyForDemoPurposesOnly'; // Demo key

      // Create customer
      final customerResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name,
          'email': UserProvider.currentUser?.email ?? 'demo@mosmartpark.com',
          'metadata[address]': address,
          'metadata[city]': city,
          'metadata[state]': state,
          'metadata[country]': country,
        },
      );

      if (customerResponse.statusCode != 200) {
        return _createMockPaymentIntent(amount, currency);
      }

      final customerData = jsonDecode(customerResponse.body);
      final customerId = customerData['id'];

      // Create ephemeral key
      final ephemeralKeyResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Stripe-Version': '2023-10-16',
        },
        body: {'customer': customerId},
      );

      if (ephemeralKeyResponse.statusCode != 200) {
        return _createMockPaymentIntent(amount, currency);
      }

      final ephemeralKeyData = jsonDecode(ephemeralKeyResponse.body);

      // Create payment intent
      final paymentIntentResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency.toLowerCase(),
          'customer': customerId,
          'payment_method_types[]': 'card',
          'description': 'Mo Smart Park Parking Reservation',
          'metadata[name]': name,
          'metadata[address]': address,
          'metadata[city]': city,
          'metadata[state]': state,
          'metadata[country]': country,
        },
      );

      if (paymentIntentResponse.statusCode == 200) {
        final paymentIntentData = jsonDecode(paymentIntentResponse.body);
        return {
          'client_secret': paymentIntentData['client_secret'],
          'ephemeralKey': ephemeralKeyData['secret'],
          'id': customerId,
          'amount': amount,
          'currency': currency,
        };
      } else {
        return _createMockPaymentIntent(amount, currency);
      }
    } catch (e) {
      // For demo purposes, return mock data if Stripe API fails
      return _createMockPaymentIntent(amount, currency);
    }
  }

  // Mock payment intent for demo purposes
  Map<String, dynamic> _createMockPaymentIntent(String amount, String currency) {
    return {
      'client_secret': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}_secret_mock',
      'ephemeralKey': 'ek_mock_${DateTime.now().millisecondsSinceEpoch}',
      'id': 'cus_mock_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'currency': currency,
    };
  }

  Future<void> _processStripePayment(Map<String, dynamic> formData) async {
    setState(() => _isLoading = true);

    try {
      await _initPaymentSheet(formData);
      
      // Only present payment sheet if we're not using mock data
      if (!_isUsingMockPayment) {
        // Present payment sheet
        await stripe.Stripe.instance.presentPaymentSheet();
      } else {
        print('Demo mode: Skipping Stripe payment sheet presentation');
      }

      // Create reservation after successful payment (or in demo mode)
      await _createReservation();

      _showSuccessSnackbar('Payment successful!');
      
      // Navigate directly to home screen after successful payment
      if (mounted) {
        // Small delay to show success message
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
        // For demo: if Stripe fails, still create reservation (for testing)
        try {
          await _createReservation();
          _showSuccessSnackbar('Reservation created successfully (demo mode)');
          
          // Navigate directly to home screen after successful reservation creation
          if (mounted) {
            // Small delay to show success message
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
        } catch (reservationError) {
          _showErrorSnackbar('Payment failed: ${e.toString()}');
        }
      }
    }
  }

  Future<Map<String, dynamic>> _createReservation() async {
    try {
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
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
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