// lib/screens/dashboard/owner_dashboard.dart

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

  // --- LOGIC: If this list is empty, we show the "Add Turf Now" button ---
  // I have commented out the data to simulate a new user with NO turfs.
  // Uncomment the data inside to see the "List View".
  final List<Map<String, String>> myTurfs = [
    // {
    //   "name": "Galaxy Sports Arena",
    //   "address": "4th Floor, Globe Estate, Dombivli East",
    //   "image": "",
    //   "rating": "4.5"
    // },
    // {
    //   "name": "Smash Turf",
    //   "address": "Vikas Naka, New Kalyan Road",
    //   "image": "",
    //   "rating": "4.8"
    // },
  ];

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color backgroundColor = const Color(0xFF121212); // Deep Matte Black
    final Color cardColor = const Color(0xFF1E1E1E);       // Dark Grey
    final Color accentColor = const Color(0xFF00E676);     // Electric Green

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back,",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- Stats Section ---
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: "Today's Bookings",
                          value: "0", // dynamic data here later
                          icon: Icons.confirmation_number_outlined,
                          color: Colors.blueAccent,
                          bgColor: cardColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _statCard(
                          title: "Total Earnings",
                          value: "₹ 0", // dynamic data here later
                          icon: Icons.attach_money_rounded,
                          color: accentColor,
                          bgColor: cardColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- TURF LIST LOGIC ---
                  if (myTurfs.isEmpty)
                  // 1. EMPTY STATE (No Turfs)
                    _buildEmptyState(accentColor)
                  else ...[
                    // 2. LIST STATE (Has Turfs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Your Turfs",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Small "Add" button when list exists
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, "/addTurf"),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Icon(Icons.add, color: accentColor, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: myTurfs.map((turf) => _buildTurfCard(turf, cardColor, accentColor)).toList(),
                    ),
                  ],

                ],
              ),
            ),
          ),

          // Floating Nav Bar
          FloatingNavBar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) {
              setState(() => _selectedIndex = i);
            },
          ),
        ],
      ),
    );
  }

  // ---------- EMPTY STATE WIDGET ----------
  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
                Icons.sports_soccer_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.2)
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Turf Added Yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "List your turf to start getting bookings.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),

          // BIG BUTTON: Add Your Turf Now
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/addTurf");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black, // Text Color
                elevation: 10,
                shadowColor: accentColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Add Your Turf Now",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- STAT CARD ----------
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- TURF CARD ----------
  Widget _buildTurfCard(Map<String, String> turf, Color cardColor, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[900],
              child: turf["image"] != ""
                  ? Image.asset(turf["image"]!, fit: BoxFit.cover)
                  : const Center(
                child: Icon(Icons.image, color: Colors.white24, size: 50),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turf["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  turf["address"] ?? "",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Manage Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Manage Turf"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}