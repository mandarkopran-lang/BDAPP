import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      Fluttertoast.showToast(msg: 'Enter the 6-digit OTP');
      return;
    }
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.authService.verifyOtpAndSignIn(
        smsCode: _otpController.text.trim(),
        verificationId: _verificationId,
      );
      // Router redirect handles navigation automatically once auth state
      // + Firestore profile stream update.
    } on FirebaseAuthException catch (e) {
      String message = 'Invalid OTP. Please try again.';
      if (e.code == 'invalid-verification-code') {
        message = 'Incorrect OTP entered.';
      } else if (e.code == 'session-expired') {
        message = 'OTP expired. Please resend.';
      }
      Fluttertoast.showToast(msg: message);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.authService.sendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        setState(() => _verificationId = verificationId);
        Fluttertoast.showToast(msg: 'OTP resent');
      },
      onAutoVerified: (credential) async {
        await authProvider.authService.signInWithCredential(credential);
      },
      onError: (e) => Fluttertoast.showToast(msg: e.message ?? 'Failed to resend'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the code sent to ${widget.phoneNumber}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 44,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: Colors.grey.shade300,
                ),
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Verify & Continue',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Resend OTP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
