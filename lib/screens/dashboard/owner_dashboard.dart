// lib/screens/dashboard/owner_dashboard.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/floating_nav_bar.dart';
import '../turf/turf_slot_page.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  String get firstName {
    if (user?.displayName == null || user!.displayName!.isEmpty) {
      return user?.phoneNumber ?? "Owner";
    }
    return user!.displayName!.split(" ").first;
  }

  final List<Map<String, String>> myTurfs = [
    {
      "name": "Galaxy sports arena",
      "address":
      "4th Floor, Globe Estate, New Kalyan Rd, Vikas Naka, Dombivli East, Maharashtra 421203",
      "image": ""
    },
    {
      "name": "Galaxy sports arena",
      "address":
      "4th Floor, Globe Estate, New Kalyan Rd, Vikas Naka, Dombivli East, Maharashtra 421203",
      "image": ""
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Turf Image
        Positioned.fill(
          child: Image.asset(
            "assets/images/turf_bg.png",
            fit: BoxFit.cover,
          ),
        ),

        // Dim Layer
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.55)),
        ),

        // Transparent Scaffold Layer
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // Greeting
                        Text(
                          "Hello, $firstName 👋",
                          style: const TextStyle(
                            fontSize: 33,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Manage your turf and booking here",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),

                        const SizedBox(height: 22),

                        // Summary Row
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                icon: Icons.calendar_month_rounded,
                                value: "12",
                                title: "Today's booking",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                icon: Icons.currency_rupee_rounded,
                                value: "₹ 4,800",
                                title: "Earning",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        // const SizedBox(height: 22),

// ⭐ Add Turf Button — START
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, "/addTurf"),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_business_rounded,
                                        color: Colors.greenAccent, size: 26),
                                    SizedBox(width: 12),
                                    Text(
                                      "Add New Turf",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
// ⭐ Add Turf Button — END

                        const SizedBox(height: 22),



                        // Turf Cards
                        for (var t in myTurfs) ...[
                          _turfCard(t),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Nav Bar (Fixed at Bottom)
              FloatingNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: (i) {
                  setState(() => _selectedIndex = i);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- SUMMARY CARD ----------
  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String title,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: Colors.greenAccent),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- TURF CARD ----------
  Widget _turfCard(Map<String, String> turf) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerTurfSlotPage(
              turfName: turf["name"] ?? "",
              turfImage: turf["image"] ?? "",
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                // Left Text Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turf["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        turf["address"] ?? "",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right Image Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.image, color: Colors.white38, size: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
