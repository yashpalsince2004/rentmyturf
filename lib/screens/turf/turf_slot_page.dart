import 'package:flutter/material.dart';

class OwnerTurfSlotPage extends StatefulWidget {
  final String turfName;
  final String turfImage;

  const OwnerTurfSlotPage({
    super.key,
    required this.turfName,
    required this.turfImage,
  });

  @override
  State<OwnerTurfSlotPage> createState() => _OwnerTurfSlotPageState();
}

class _OwnerTurfSlotPageState extends State<OwnerTurfSlotPage> {
  int selectedDateIndex = 0;
  int selectedTimeIndex = 1;
  int selectedSession = 2;

  final sessions = ["Morning", "Afternoon", "Evening"];
  final sessionIcons = [Icons.wb_sunny, Icons.wb_twilight, Icons.nights_stay];

  final dates = [
    {"week": "SAT", "day": "29", "month": "NOV"},
    {"week": "SUN", "day": "30", "month": "NOV"},
    {"week": "MON", "day": "1", "month": "DEC"},
    {"week": "TUE", "day": "2", "month": "DEC"},
    {"week": "WED", "day": "3", "month": "DEC"},
    {"week": "THU", "day": "4", "month": "DEC"},
  ];

  final timeSlots = [
    "5:00 PM",
    "6:00 PM",
    "7:00 PM",
    "8:00 PM",
    "9:00 PM",
    "10:00 PM"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        ),
        centerTitle: true,
        title: Text(
          widget.turfName,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Column(
        children: [
          // ---------------- Turf Image Section ----------------
          SizedBox(
            height: 220,
            width: double.infinity,
            child: widget.turfImage.isEmpty
                ? Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.image_not_supported,
                    size: 40, color: Colors.grey),
              ),
            )
                : Image.network(
              widget.turfImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image,
                      size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),

          // ---------------- Main Scroll View ----------------
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Date Selector ----------------
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final d = dates[index];
                        final selected = selectedDateIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => selectedDateIndex = index),
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              color: selected ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d["week"]!,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d["day"]!,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  d["month"]!,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ---------------- Session Selector ----------------
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: List.generate(
                        sessions.length,
                            (i) {
                          final isSelected = selectedSession == i;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedSession = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                decoration: BoxDecoration(
                                  color:
                                  isSelected ? Colors.green : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isSelected)
                                      const Icon(Icons.check,
                                          color: Colors.white, size: 18),
                                    if (isSelected)
                                      const SizedBox(width: 6),
                                    Text(
                                      sessions[i],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ---------------- Available Slots ----------------
                  const Text(
                    "Available Slots",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: List.generate(timeSlots.length, (i) {
                      final selected = selectedTimeIndex == i;

                      return GestureDetector(
                        onTap: () => setState(() => selectedTimeIndex = i),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? Colors.green : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected
                                    ? Colors.green
                                    : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              timeSlots[i],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ---------------- Bottom Booking Button ----------------
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Book 1 Slot  |  ₹600",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
