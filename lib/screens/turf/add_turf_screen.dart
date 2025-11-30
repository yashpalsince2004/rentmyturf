import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {

      // 🔥 LIMIT MAX 10 IMAGES
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
    final ref = FirebaseStorage.instance
        .ref()
        .child("turfs/$turfId/${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveTurf() async {
    if (!_formKey.currentState!.validate()) return;

    // 🔥 Add this price validation HERE
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

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final turfId = FirebaseFirestore.instance.collection("turfs").doc().id;

    // Upload images
    List<String> imageUrls = [];
    for (var img in images) {
      final url = await uploadImage(img, turfId);
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
      "openingTime": openingTime != null
          ? formatTime(openingTime!)
          : "06:00",

      "closingTime": closingTime != null
          ? formatTime(closingTime!)
          : "23:00",

      "images": imageUrls,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Update owner's turf list
    await FirebaseFirestore.instance
        .collection("owners")
        .doc(uid)
        .set({
      "turfsOwned": FieldValue.arrayUnion([turfId])
    },SetOptions(merge: true));

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Turf added successfully!")),
    );

    Navigator.pop(context);
  }

  Future<void> pickOpeningTime() async {
    final t =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => openingTime = t);
  }

  Future<void> pickClosingTime() async {
    final t =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => closingTime = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/images/turf_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // DARK OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // --- MODIFIED HEADER WITH BACK BUTTON ---
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: const ButtonStyle(
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                "Add Turf",
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // ----------------------------------------

                          const SizedBox(height: 20),

                          buildInput("Turf Name", nameCtrl),
                          buildInput("Address", addressCtrl),
                          buildInput("City", cityCtrl),
                          buildInput("Price Per Hour", priceCtrl,
                              type: TextInputType.number),

                          const SizedBox(height: 14),

                          timePickerRow(),

                          const SizedBox(height: 20),

                          imagePickerSection(),

                          const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed: isSaving ? null : saveTurf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                                : const Text(
                              "Save Turf",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInput(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          validator: (v) => v!.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget timePickerRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: pickOpeningTime,
            child: _glassBox(
              "Opening Time",
              openingTime != null
                  ? openingTime!.format(context)
                  : "Select",
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: pickClosingTime,
            child: _glassBox(
              "Closing Time",
              closingTime != null ? closingTime!.format(context) : "Select",
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget imagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Turf Images",
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...images
                .map((img) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(img,
                  width: 90, height: 90, fit: BoxFit.cover),
            ))
                .toList(),
            GestureDetector(
              onTap: pickImages,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(Icons.add_a_photo, color: Colors.greenAccent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}