import 'package:flutter/material.dart';

class OwnerPhoneLoginScreen extends StatelessWidget {
  const OwnerPhoneLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Phone Login"),
      ),
      body: const Center(
        child: Text(
          "Phone OTP Login UI Coming Soon...",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
