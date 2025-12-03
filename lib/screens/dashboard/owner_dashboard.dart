import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/floating_nav_bar.dart';
import '../turf/manage_turf_page.dart';
import '../turf/turf_schedule_screen.dart'; // <--- IMPORT THE NEW FILE

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  // --- 1. DEFINE THE PAGES ---
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomeContent(),          // Index 0: Home (Stats & List)
      const TurfScheduleScreen(),   // Index 1: Calendar/Schedule
      const Center(child: Text("Profile Page", style: TextStyle(color: Colors.white))), // Index 2: Profile
    ];
  }

  String get firstName {
    if (user?.displayName == null || user!.displayName!.isEmpty) {
      return user?.phoneNumber ?? "Owner";
    }
    return user!.displayName!.split(" ").first;
  }

  // Theme Colors
  final Color backgroundColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color accentColor = const Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // --- 2. SWITCH CONTENT BASED ON INDEX ---
          SafeArea(
            bottom: false,
            // Uses IndexedStack to preserve state (so calendar doesn't reset when switching tabs)
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),

          // --- 3. FLOATING NAV BAR ---
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

  // ==========================================
  //      ORIGINAL DASHBOARD CONTENT (HOME)
  // ==========================================
  Widget _buildHomeContent() {
    return SingleChildScrollView(
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
                  value: "0",
                  icon: Icons.confirmation_number_outlined,
                  color: Colors.blueAccent,
                  bgColor: cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  title: "Total Earnings",
                  value: "₹ 0",
                  icon: Icons.attach_money_rounded,
                  color: accentColor,
                  bgColor: cardColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // --- REAL-TIME TURF DATA STREAM ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('turfs')
                .where('ownerId', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              // 1. Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent));
              }

              // 2. Error State
              if (snapshot.hasError) {
                return Center(
                    child: Text("Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white)));
              }

              // 3. Empty State (No Turfs found in DB)
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(accentColor);
              }

              // 4. Data Exists - Show List
              var docs = snapshot.data!.docs;

              return Column(
                children: [
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
                  // Map the documents to Cards
                  ...docs.map((doc) {
                    Map<String, dynamic> data =
                    doc.data() as Map<String, dynamic>;
                    return _buildTurfCard(data, cardColor, accentColor, context);
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- HELPER WIDGETS ----------

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sports_soccer_rounded,
                size: 80, color: Colors.white.withOpacity(0.2)),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Turf Added Yet",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "List your turf to start getting bookings.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/addTurf"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                elevation: 10,
                shadowColor: accentColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Add Your Turf Now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      {required String title,
        required String value,
        required IconData icon,
        required Color color,
        required Color bgColor}) {
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
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title,
              style:
              TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildTurfCard(Map<String, dynamic> data, Color cardColor,
      Color accentColor, BuildContext context) {
    String name = data['turf_name'] ?? data['name'] ?? "Unnamed Turf";
    String address =
        data['address'] ?? data['location'] ?? "No address provided";

    String? imageUrl;
    if (data['images'] != null &&
        (data['images'] is List) &&
        (data['images'] as List).isNotEmpty) {
      imageUrl = (data['images'] as List).first;
    } else if (data['image'] is String) {
      imageUrl = data['image'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[900],
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white24)),
              )
                  : const Center(
                  child: Icon(Icons.image, color: Colors.white24, size: 50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(address,
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageTurfPage(turfId: data['turfId']),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
