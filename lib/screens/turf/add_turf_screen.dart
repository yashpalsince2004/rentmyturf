import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';

class AddTurfScreen extends StatefulWidget {
  const AddTurfScreen({super.key});

  @override
  State<AddTurfScreen> createState() => _AddTurfScreenState();
}

class _AddTurfScreenState extends State<AddTurfScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  // 1. NEW CONTROLLER
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  // City Dropdown Logic
  String? selectedCity;
  final List<String> cities = [
    "Mumbai", "Pune", "Delhi", "Bangalore", "Hyderabad",
    "Chennai", "Kolkata", "Ahmedabad", "Kalyan", "Thane",
    "Navi Mumbai", "Nashik", "Nagpur"
  ];

  String formatTime12(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;

  List<File> images = [];
  bool isSaving = false;

  final Color backgroundColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color accentColor = const Color(0xFF00E676);
  final Color inputColor = const Color(0xFF2C2C2C);

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  Future<void> saveTurf() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a city")),
      );
      return;
    }

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least 1 image")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final turfId = FirebaseFirestore.instance.collection("turfs").doc().id;

      // Upload Images
      List<String> imageUrls = [];
      for (var img in images) {
        final url = await CloudinaryService.uploadTurfImage(img);
        imageUrls.add(url);
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection("turfs").doc(turfId).set({
        "turfId": turfId,
        "ownerId": uid,
        "turf_name": nameCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        "city": selectedCity,
        "description": descCtrl.text.trim(), // 2. SAVE DESCRIPTION
        "price_per_hour": int.parse(priceCtrl.text.trim()),
        "open_time": openingTime != null ? formatTime12(openingTime!) : "06:00 AM",
        "close_time": closingTime != null ? formatTime12(closingTime!) : "11:00 PM",
        "images": imageUrls,
        "rating": "0.0",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection("owners").doc(uid).set({
        "turfsOwned": FieldValue.arrayUnion([turfId])
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Turf added successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> pickOpeningTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
                primary: accentColor, onPrimary: Colors.black, surface: cardColor, onSurface: Colors.white),
          ),
          child: child!),
    );
    if (t != null) setState(() => openingTime = t);
  }

  Future<void> pickClosingTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
                primary: accentColor, onPrimary: Colors.black, surface: cardColor, onSurface: Colors.white),
          ),
          child: child!),
    );
    if (t != null) setState(() => closingTime = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Add New Turf", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: backgroundColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInput("Turf Name", nameCtrl, icon: Icons.sports_soccer),
                    buildInput("Address", addressCtrl, icon: Icons.location_on_outlined),

                    // City Dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("City", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            decoration: BoxDecoration(
                              color: inputColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCity,
                                hint: const Text("Select City", style: TextStyle(color: Colors.white54)),
                                dropdownColor: cardColor,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                items: cities.map((String city) {
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => selectedCity = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. NEW DESCRIPTION INPUT (Multi-line)
                    buildInput("Description", descCtrl, icon: Icons.description_outlined, maxLines: 3),

                    buildInput("Price Per Hour (₹)", priceCtrl, type: TextInputType.number, icon: Icons.currency_rupee),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: GestureDetector(onTap: pickOpeningTime, child: _timeBox("Opening", openingTime))),
                        const SizedBox(width: 16),
                        Expanded(child: GestureDetector(onTap: pickClosingTime, child: _timeBox("Closing", closingTime))),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text("Turf Images", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: [
                        GestureDetector(
                          onTap: pickImages,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(16)),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_a_photo_rounded, color: accentColor, size: 28),
                              const SizedBox(height: 8),
                              Text("Add Photo", style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold))
                            ]),
                          ),
                        ),
                        ...images.map((img) => Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(img, width: 100, height: 100, fit: BoxFit.cover)),
                          Positioned(right: 4, top: 4, child: GestureDetector(onTap: () => setState(() => images.remove(img)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)))),
                        ])).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveTurf,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: isSaving ? const CircularProgressIndicator(color: Colors.black) : const Text("Publish Turf", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UPDATED HELPER WIDGET ---
  Widget buildInput(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, required IconData icon, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines, // Updated to support multiple lines
            style: const TextStyle(color: Colors.white, fontSize: 16),
            validator: (v) => v!.isEmpty ? "Required" : null,
            decoration: InputDecoration(
              filled: true, fillColor: inputColor,
              prefixIcon: Padding(
                // Adjust icon alignment for tall text boxes
                padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
                child: Icon(icon, color: Colors.white54, size: 20),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String title, TimeOfDay? time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: time != null ? accentColor.withOpacity(0.5) : Colors.transparent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.access_time_rounded, color: Colors.white54, size: 16), const SizedBox(width: 6), Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13))]),
          const SizedBox(height: 8),
          Text(time != null ? formatTime12(time) : "-- : --", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}