import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TurfBookingConfirmScreen extends StatefulWidget {
  final String turfId;
  final String turfName;
  final DateTime date;
  final List<String> selectedSlots;
  final double pricePerSlot;

  const TurfBookingConfirmScreen({
    super.key,
    required this.turfId,
    required this.turfName,
    required this.date,
    required this.selectedSlots,
    required this.pricePerSlot,
  });

  @override
  State<TurfBookingConfirmScreen> createState() => _TurfBookingConfirmScreenState();
}

class _TurfBookingConfirmScreenState extends State<TurfBookingConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  double _remainingAmount = 0.0;
  bool isBooking = false;

  // Colors
  final Color backgroundColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color accentColor = const Color(0xFF00E676);

  @override
  void initState() {
    super.initState();

    // Calculate Default Total
    double defaultTotal = widget.selectedSlots.length * widget.pricePerSlot;

    // Pre-fill the Total Amount (ensure not empty)
    _totalAmountController.text = defaultTotal == 0 ? "0" : defaultTotal.toStringAsFixed(0);

    // Initialize Remaining Amount logic
    _calculateRemaining();

    _totalAmountController.addListener(_calculateRemaining);
    _paidAmountController.addListener(_calculateRemaining);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _calculateRemaining() {
    double total = double.tryParse(_totalAmountController.text) ?? 0.0;
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    setState(() {
      _remainingAmount = total - paid;
      if (_remainingAmount < 0) _remainingAmount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEE, d MMM yyyy').format(widget.date);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Confirm Walk-in", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. SUMMARY CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    _rowSummary("Turf", widget.turfName),
                    const SizedBox(height: 12),
                    _rowSummary("Date", formattedDate),
                    const SizedBox(height: 12),
                    _rowSummary("Slots", "${widget.selectedSlots.length} Selected"),
                    const SizedBox(height: 12),
                    _rowSummary("Rate", "₹ ${widget.pricePerSlot.toStringAsFixed(0)} / slot"),
                    const Divider(color: Colors.white24, height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.selectedSlots.map((slot) => Chip(
                        label: Text(slot, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: accentColor,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text("Customer Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // --- 2. INPUT: NAME ---
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Customer Name", Icons.person_outline),
                validator: (val) => val == null || val.isEmpty ? "Enter customer name" : null,
              ),

              const SizedBox(height: 20),

              // --- 3. INPUT: PHONE NUMBER (LIMIT 10 DIGITS) ---
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                maxLength: 10, // 🔹 Limits input to 10 chars
                decoration: _inputDecoration("Phone Number", Icons.phone_android_rounded).copyWith(
                  counterText: "", // Hides the "0/10" counter text for cleanliness
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter phone number";
                  if (val.length != 10) return "Phone number must be exactly 10 digits";
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // --- 4. INPUT: TOTAL & PAID AMOUNT ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalAmountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Total Amount", Icons.attach_money),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (double.tryParse(val) == null) return "Invalid";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _paidAmountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Amount Paid", Icons.check_circle_outline),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- 5. DISPLAY: REMAINING AMOUNT ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Remaining Amount:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text(
                      "₹ ${_remainingAmount.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 6. CONFIRM BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isBooking ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isBooking
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("Confirm Booking", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: accentColor),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor)),
    );
  }

  Widget _rowSummary(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- LOGIC: SUBMIT ---
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isBooking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String dbDateKey = DateFormat('yyyy-MM-dd').format(widget.date);

      double total = double.parse(_totalAmountController.text);
      double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
      double remaining = total - paid;

      await FirebaseFirestore.instance.collection('bookings').add({
        'turfId': widget.turfId,
        'date': dbDateKey,
        'slots': widget.selectedSlots,
        'bookedBy': "Owner (Walk-in)",
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'totalAmount': total,
        'amountPaid': paid,
        'remainingAmount': remaining,
        'ownerId': user?.uid,
        'status': 'confirmed',
        'timestamp': FieldValue.serverTimestamp(),
        'paymentStatus': remaining <= 0 ? 'Full Paid' : (paid > 0 ? 'Partial' : 'Pending'),
        'isWalkIn': true,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => isBooking = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }
}