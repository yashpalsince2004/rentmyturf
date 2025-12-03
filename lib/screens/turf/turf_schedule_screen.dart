import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rentmyturf/screens/turf/turf_booking_confirm_screen.dart';

class TurfScheduleScreen extends StatefulWidget {
  const TurfScheduleScreen({super.key});

  @override
  State<TurfScheduleScreen> createState() => _TurfScheduleScreenState();
}

class _TurfScheduleScreenState extends State<TurfScheduleScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String? selectedTurfId;
  DateTime selectedDate = DateTime.now();

  Set<String> selectedWalkInSlots = {};
  bool isBooking = false;

  // Colors
  final Color backgroundColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color accentColor = const Color(0xFF00E676);
  final Color bookedColor = const Color(0xFFFF5252);
  final Color calendarSelectedColor = const Color(0xFF4CAF50);
  final Color weekendColor = const Color(0xFFFF9800); // Orange for Weekends

  @override
  Widget build(BuildContext context) {
    String dbDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("Manage Slots",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
      ),
      body: Stack(
        children: [
          // --- LAYER 1: CONTENT ---
          Column(
            children: [
              _buildTurfDropdown(),
              const SizedBox(height: 10),
              _buildHorizontalCalendar(),
              const SizedBox(height: 10),

              Expanded(
                child: selectedTurfId == null
                    ? Center(
                    child: Text("Select a turf to load slots",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 16)))
                    : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('turfs')
                      .doc(selectedTurfId)
                      .snapshots(),
                  builder: (context, turfSnap) {
                    if (!turfSnap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.greenAccent));
                    }

                    var turfData =
                    turfSnap.data!.data() as Map<String, dynamic>?;

                    if (turfData == null) return const SizedBox();

                    String? openingTime =
                    _convertToAmPm(turfData['open_time']);
                    String? closingTime =
                    _convertToAmPm(turfData['close_time']);

                    if (openingTime == null || closingTime == null) {
                      return const Center(
                          child: Text("Invalid Time Settings",
                              style: TextStyle(color: Colors.white)));
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('turfId', isEqualTo: selectedTurfId)
                          .where('date', isEqualTo: dbDateKey)
                          .snapshots(),
                      builder: (context, bookSnap) {
                        List<String> bookedFromDB = [];

                        if (bookSnap.hasData) {
                          for (var doc in bookSnap.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            if (data['slots'] != null) {
                              bookedFromDB
                                  .addAll(List<String>.from(data['slots']));
                            }
                          }
                        }

                        List<String> allSlots =
                        _generateSlots(openingTime, closingTime);

                        if (allSlots.isEmpty) {
                          return const Center(
                              child: Text("No slots available.",
                                  style: TextStyle(
                                      color: Colors.white54)));
                        }

                        Map<String, List<String>> categorized =
                        _categorizeSlots(allSlots);

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection("Morning",
                                  categorized['Morning']!, bookedFromDB),
                              _buildSection("Afternoon",
                                  categorized['Afternoon']!, bookedFromDB),
                              _buildSection("Evening",
                                  categorized['Evening']!, bookedFromDB),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // --- LAYER 2: FLOATING BOOKING BAR ---
          if (selectedWalkInSlots.isNotEmpty)
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: isBooking ? null : _confirmBooking,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${selectedWalkInSlots.length} Slot(s) Selected",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Tap to confirm booking",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (isBooking)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      else
                        const Row(
                          children: [
                            Text(
                              "Book Now",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.black, size: 20),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // 🔹 CALENDAR (UPDATED: Orange for Weekends)
  // ------------------------------------------------------------------
  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 15,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);

          // Check if it is Saturday (6) or Sunday (7)
          final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

          // Determine Colors
          Color bgColor;
          Color borderColor;
          Color textColor = Colors.white;
          Color subTextColor = Colors.white54;

          if (isSelected) {
            bgColor = calendarSelectedColor;
            borderColor = Colors.transparent;
            textColor = Colors.white;
            subTextColor = Colors.white;
          } else if (isWeekend) {
            bgColor = weekendColor.withOpacity(0.15); // Orange Tint
            borderColor = weekendColor.withOpacity(0.4);
            textColor = weekendColor; // Optional: Make text orange too?
            subTextColor = weekendColor.withOpacity(0.7);
          } else {
            bgColor = cardColor;
            borderColor = Colors.white.withOpacity(0.1);
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
                selectedWalkInSlots.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? null : Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(DateFormat('d').format(date),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(DateFormat('MMM').format(date).toUpperCase(),
                      style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // 🔹 DROPDOWN
  // ------------------------------------------------------------------
  Widget _buildTurfDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('turfs')
          .where('ownerId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50);
        var turfs = snapshot.data!.docs;
        if (turfs.isEmpty) return const SizedBox();

        if (selectedTurfId == null) selectedTurfId = turfs.first['turfId'];

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTurfId,
              dropdownColor: cardColor,
              icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: turfs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: data['turfId'],
                  child: Text(data['turf_name'] ?? "Unnamed Turf",
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedTurfId = val;
                  selectedWalkInSlots.clear();
                });
              },
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // 🔹 SECTION BUILDER
  // ------------------------------------------------------------------
  Widget _buildSection(
      String title, List<String> slots, List<String> bookedFromDB) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Icon(
                title == "Morning"
                    ? Icons.wb_sunny_outlined
                    : title == "Afternoon"
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            String slot = slots[index];
            bool isBooked = bookedFromDB.contains(slot);
            bool isSelected = selectedWalkInSlots.contains(slot);

            Color bgColor = cardColor;
            Color borderColor = Colors.white12;
            Color textColor = Colors.white;

            if (isBooked) {
              bgColor = bookedColor.withOpacity(0.15);
              borderColor = bookedColor;
              textColor = bookedColor;
            } else if (isSelected) {
              bgColor = accentColor.withOpacity(0.2);
              borderColor = accentColor;
              textColor = accentColor;
            }

            return GestureDetector(
              onTap: () {
                if (isBooked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Slot already booked!"),
                        duration: Duration(milliseconds: 500)),
                  );
                  return;
                }
                setState(() {
                  if (isSelected) {
                    selectedWalkInSlots.remove(slot);
                  } else {
                    selectedWalkInSlots.add(slot);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  slot,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // 🔹 CONFIRM BOOKING (FIXED FOR 'price_per_hour')
  // ------------------------------------------------------------------
  Future<void> _confirmBooking() async {
    if (selectedTurfId == null || selectedWalkInSlots.isEmpty) return;

    try {
      // 1. Fetch Turf Data to get the Price
      DocumentSnapshot turfSnap = await FirebaseFirestore.instance
          .collection('turfs')
          .doc(selectedTurfId)
          .get();

      double pricePerSlot = 0.0;
      String turfName = "Turf";

      if (turfSnap.exists) {
        var data = turfSnap.data() as Map<String, dynamic>;

        turfName = data['turf_name'] ?? data['name'] ?? "Turf";

        // 🔹 EXACT MATCH: Checking 'price_per_hour' first as seen in your DB
        var rawPrice = data['price_per_hour'] ?? data['price'] ?? 0;

        // Handle both String ("900") and Number (900) formats safely
        pricePerSlot = double.tryParse(rawPrice.toString()) ?? 0.0;

        // Debug print to check in your console if needed
        print("DEBUG: Fetched Price: $pricePerSlot for $turfName");
      }

      if (!mounted) return;

      // 2. Navigate to Confirm Screen with the fetched price
      final bool? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TurfBookingConfirmScreen(
            turfId: selectedTurfId!,
            turfName: turfName,
            date: selectedDate,
            selectedSlots: selectedWalkInSlots.toList(),
            pricePerSlot: pricePerSlot, // Passing the 900 value here
          ),
        ),
      );

      // 3. Handle Success
      if (result == true) {
        setState(() {
          selectedWalkInSlots.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Walk-in booking confirmed!"),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching price: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ------------------------------------------------------------------
  // 🔹 HELPERS
  // ------------------------------------------------------------------
  String? _convertToAmPm(String? time24) {
    if (time24 == null) return null;
    try {
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      String ampm = hour >= 12 ? "PM" : "AM";
      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      return "${hour12.toString().padLeft(2, '0')}:${parts[1]} $ampm";
    } catch (e) {
      return null;
    }
  }

  List<String> _generateSlots(String opening, String closing) {
    List<String> slots = [];
    DateFormat format = DateFormat("hh:mm a");
    try {
      DateTime start = format.parse(opening);
      DateTime end = format.parse(closing);
      if (end.isBefore(start)) end = end.add(const Duration(days: 1));
      while (start.isBefore(end)) {
        slots.add(format.format(start));
        start = start.add(const Duration(hours: 1));
      }
    } catch (e) {
      return [];
    }
    return slots;
  }

  Map<String, List<String>> _categorizeSlots(List<String> allSlots) {
    List<String> morning = [];
    List<String> afternoon = [];
    List<String> evening = [];
    DateFormat parser = DateFormat("hh:mm a");

    for (var slot in allSlots) {
      try {
        DateTime dt = parser.parse(slot);
        int hour = dt.hour;
        if (hour < 12) {
          morning.add(slot);
        } else if (hour >= 12 && hour < 16) {
          afternoon.add(slot);
        } else {
          evening.add(slot);
        }
      } catch (e) {
        evening.add(slot);
      }
    }
    return {
      "Morning": morning,
      "Afternoon": afternoon,
      "Evening": evening,
    };
  }
}