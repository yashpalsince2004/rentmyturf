// lib/screens/auth/owner_otp_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/owner_service.dart';

class OwnerOtpScreen extends StatefulWidget {
  final String verificationId;
  const OwnerOtpScreen({super.key, required this.verificationId});

  @override
  State<OwnerOtpScreen> createState() => _OwnerOtpScreenState();
}

class _OwnerOtpScreenState extends State<OwnerOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;

  // Theme Colors
  final Color backgroundColor = const Color(0xFF121212); // Matte Black
  final Color cardColor = const Color(0xFF1E1E1E);       // Dark Grey
  final Color accentColor = const Color(0xFF00E676);     // Electric Green

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();

    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 6-digit OTP")),
      );
      return;
    }

    setState(() => _verifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await OwnerService.saveOwner();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/dashboard");

    } catch (e) {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP, please try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: size.width * 0.9, // Slightly wider for better mobile fit
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded, size: 32, color: accentColor),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the 6-digit code sent to your phone number.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 30),

                // OTP Input Field
                TextField(
                  controller: _otpController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8, // Spacing out the numbers for OTP look
                  ),
                  cursorColor: accentColor,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••••",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 8),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Verify Button
                ElevatedButton(
                  onPressed: _verifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                  )
                      : const Text(
                    "Verify OTP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Phone Link
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 16),
                      const SizedBox(width: 8),
                      const Text("Change phone number"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}