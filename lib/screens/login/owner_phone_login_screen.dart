// lib/screens/auth/owner_phone_login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerPhoneLoginScreen extends StatefulWidget {
  const OwnerPhoneLoginScreen({super.key});

  @override
  State<OwnerPhoneLoginScreen> createState() => _OwnerPhoneLoginScreenState();
}

class _OwnerPhoneLoginScreenState extends State<OwnerPhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _sending = false;

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim();

    if (raw.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 10-digit phone number")),
      );
      return;
    }

    final phone = '+91$raw';

    setState(() => _sending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) {
          // Auto-resolved
        },
        verificationFailed: (e) {
          setState(() => _sending = false); // Stop loading on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification failed: ${e.message}")),
          );
        },
        codeSent: (verificationId, _) async {
          if (!mounted) return;
          setState(() => _sending = false);

          // navigate to OTP screen with verificationId
          Navigator.pushNamed(
            context,
            "/otp",
            arguments: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending OTP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color backgroundColor = const Color(0xFF121212);
    final Color cardColor = const Color(0xFF1E1E1E);
    final Color accentColor = const Color(0xFF00E676);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ]
                ),
                child: Icon(Icons.phone_iphone_rounded, size: 40, color: accentColor),
              ),

              const SizedBox(height: 40),

              // Login Card
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Owner Login",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Manage your turf business with ease.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Phone Input
                    Text(
                      "Phone Number",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        counterText: "",
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "+91",
                            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: "Enter mobile number",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: backgroundColor, // Input darker than card
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 1),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Send OTP Button
                    ElevatedButton(
                      onPressed: _sending ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: accentColor.withOpacity(0.5),
                      ),
                      child: _sending
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      )
                          : const Text(
                        "Send OTP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Back Button
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white.withOpacity(0.5)),
                label: Text(
                  "Back to Selection",
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}