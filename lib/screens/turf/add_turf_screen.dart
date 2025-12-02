// lib/screens/add_turf_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  String formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;

  List<File> images = [];
  bool isSaving = false;

  // --- THEME COLORS ---
  final Color backgroundColor = const Color(0xFF121212); // Deep Matte Black
  final Color cardColor = const Color(0xFF1E1E1E);       // Dark Grey
  final Color accentColor = const Color(0xFF00E676);     // Electric Green
  final Color inputColor = const Color(0xFF2C2C2C);      // Slightly lighter for inputs

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      if (images.length + picked.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can upload maximum 10 images")),
        );
        return;
      }
      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  Future<String> uploadImage(File file, String turfId) async {
    // 1. Create the reference
    final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child("turfs/$turfId/$fileName");

    try {
      // 2. Create the upload task
      final UploadTask uploadTask = ref.putFile(file);

      // 3. Listen for the snapshot to ensure completion
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});

      // 4. Verify the upload was actually successful
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception("Image upload failed. State: ${snapshot.state}");
      }
    } catch (e) {
      // This will help you see the REAL error in your console
      print("Upload Error Details: $e");
      rethrow;
    }
  }

  Future<void> saveTurf() async {
    if (!_formKey.currentState!.validate()) return;

    if (int.tryParse(priceCtrl.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid numeric price")),
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

      // Upload images
      List<String> imageUrls = [];
      for (var img in images) {
        final url = await CloudinaryService.uploadTurfImage(img);
        imageUrls.add(url);

      }

      // Save turf data into Firestore
      await FirebaseFirestore.instance.collection("turfs").doc(turfId).set({
        "turfId": turfId,
        "ownerId": uid,
        "turfName": nameCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        "city": cityCtrl.text.trim(),
        "pricePerHour": int.parse(priceCtrl.text.trim()),
        "openingTime": openingTime != null ? formatTime(openingTime!) : "06:00",
        "closingTime": closingTime != null ? formatTime(closingTime!) : "23:00",
        "images": imageUrls,
        "rating": "0.0", // Default rating
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Update owner's turf list
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
        SnackBar(content: Text("Error saving turf: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> pickOpeningTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.black,
              surface: cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (t != null) setState(() => openingTime = t);
  }

  Future<void> pickClosingTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.black,
              surface: cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (t != null) setState(() => closingTime = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          "Add New Turf",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- MAIN FORM CARD ---
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInput("Turf Name", nameCtrl, icon: Icons.sports_soccer),
                    buildInput("Address", addressCtrl, icon: Icons.location_on_outlined),
                    buildInput("City", cityCtrl, icon: Icons.location_city),
                    buildInput("Price Per Hour (₹)", priceCtrl,
                        type: TextInputType.number, icon: Icons.currency_rupee),

                    const SizedBox(height: 20),

                    // --- TIME PICKERS ---
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: pickOpeningTime,
                            child: _timeBox("Opening", openingTime),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: pickClosingTime,
                            child: _timeBox("Closing", closingTime),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- IMAGE PICKER ---
                    const Text(
                      "Turf Images",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Pick Button
                        GestureDetector(
                          onTap: pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: inputColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: accentColor, size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  "Add Photo",
                                  style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        // Image List
                        ...images.map((img) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                img,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    images.remove(img);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveTurf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  elevation: 5,
                  shadowColor: accentColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                )
                    : const Text(
                  "Publish Turf",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            validator: (v) => v!.isEmpty ? "Required" : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: inputColor,
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String title, TimeOfDay? time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: time != null ? accentColor.withOpacity(0.5) : Colors.transparent
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time != null ? time.format(context) : "-- : --",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}