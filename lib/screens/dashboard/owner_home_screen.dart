import 'package:flutter/material.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Owner Dashboard"),
      ),
      body: const Center(
        child: Text(
          "Welcome Turf Owner! 🎯",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent),
        ),
      ),
    );
  }
}
