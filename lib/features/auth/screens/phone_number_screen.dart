import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  // Default country code. Change/make dynamic as needed for your market.
  static const _countryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final phone = '$_countryCode${_phoneController.text.trim()}';

    try {
      await authProvider.authService.sendOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          context.push('/auth/otp', extra: {
            'verificationId': verificationId,
            'phoneNumber': phone,
          });
        },
        onAutoVerified: (credential) async {
          try {
            await authProvider.authService.signInWithCredential(credential);
          } catch (e) {
            Fluttertoast.showToast(msg: 'Auto sign-in failed: $e');
          }
        },
        onError: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          // Common cause mapping -> actionable message for the user.
          String message = e.message ?? 'Failed to send OTP';
          if (e.code == 'invalid-phone-number') {
            message = 'Invalid phone number format. Use 10-digit number.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many attempts. Please try again later.';
          } else if (e.code == 'app-not-authorized' ||
              e.code == 'missing-client-identifier') {
            message =
                'Firebase project misconfigured. Verify SHA-1/SHA-256 '
                'fingerprints are added in Firebase Console and '
                'google-services.json is up to date.';
          }
          Fluttertoast.showToast(msg: message, timeInSecForIosWeb: 4);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Something went wrong: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.build_circle, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your mobile number to receive an OTP',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  hint: '9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Center(
                      widthFactor: 1,
                      child: Text('+91', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.trim().length != 10) {
                      return 'Enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: _sendOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
