import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Welcome, ${user?.displayName ?? user?.phoneNumber ?? "Owner"}",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
