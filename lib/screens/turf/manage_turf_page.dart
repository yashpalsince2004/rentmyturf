import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageTurfPage extends StatefulWidget {
  final String turfId;

  const ManageTurfPage({
    super.key,
    required this.turfId,
  });

  @override
  State<ManageTurfPage> createState() => _ManageTurfPageState();
}

class _ManageTurfPageState extends State<ManageTurfPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Data
  List<dynamic> _imageUrls = [];
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  @override
  void initState() {
    super.initState();
    _fetchTurfDetails();
  }

  Future<void> _fetchTurfDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('turfs')
          .doc(widget.turfId)
          .get();

      if (doc.exists && mounted) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['turf_name'] ?? data['name'] ?? '';
          _addressController.text = data['address'] ?? data['location'] ?? '';
          _priceController.text = (data['price_per_hour'] ?? data['price'] ?? '0').toString();
          _descController.text = data['description'] ?? '';

          if (data['images'] != null && data['images'] is List) {
            _imageUrls = List.from(data['images']);
          } else if (data['image'] != null) {
            _imageUrls = [data['image']];
          }

          _openTime = _parseTime(data['open_time']);
          _closeTime = _parseTime(data['close_time']);

          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(":");
      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].split(" ")[0].trim());
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  // --- DELETE FUNCTION ---
  Future<void> _deleteTurf() async {
    // 1. Show Confirmation Dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Delete Turf?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This action cannot be undone. Are you sure you want to remove this turf?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      // 2. Perform Delete
      await FirebaseFirestore.instance.collection('turfs').doc(widget.turfId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Turf deleted successfully"), backgroundColor: Colors.redAccent),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateTurf() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('turfs').doc(widget.turfId).update({
        'turf_name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'price_per_hour': int.tryParse(_priceController.text.trim()) ?? 0,
        'description': _descController.text.trim(),
        'open_time': _openTime?.format(context) ?? "09:00 AM",
        'close_time': _closeTime?.format(context) ?? "11:00 PM",
        'images': _imageUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Turf Updated Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);
    const Color accentColor = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text("Manage Turf", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Optional: Also added a Trash icon in the App Bar
          IconButton(
            onPressed: _isSaving ? null : _deleteTurf,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGES ---
              const Text("Turf Images", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imageUrls.length) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                        child: Icon(Icons.add_a_photo, color: Colors.white.withOpacity(0.5)),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: NetworkImage(_imageUrls[index]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 5, right: 15,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _imageUrls.removeAt(index));
                            },
                            child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),

              _buildLabel("Turf Name"),
              _buildTextField(_nameController, "Enter turf name", Icons.stadium),

              _buildLabel("Address / Location"),
              _buildTextField(_addressController, "Enter address", Icons.location_on),

              _buildLabel("Price Per Hour (₹)"),
              _buildTextField(_priceController, "Ex: 800", Icons.currency_rupee, isNumber: true),

              _buildLabel("Description"),
              _buildTextField(_descController, "Describe amenities...", Icons.description, maxLines: 4),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildLabel("Opening Time"), _buildTimePickerButton(_openTime?.format(context) ?? "Select", () async {
                      final t = await _pickTime(true);
                      if(t!=null) setState(() => _openTime = t);
                    }, cardColor)],
                  )),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildLabel("Closing Time"), _buildTimePickerButton(_closeTime?.format(context) ?? "Select", () async {
                      final t = await _pickTime(false);
                      if(t!=null) setState(() => _closeTime = t);
                    }, cardColor)],
                  )),
                ],
              ),

              const SizedBox(height: 40),

              // --- UPDATE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateTurf,
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("Update Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // --- DELETE BUTTON (New) ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _deleteTurf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete Turf", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Time Picker
  Future<TimeOfDay?> _pickTime(bool isOpening) async {
    return showTimePicker(
      context: context,
      initialTime: isOpening ? (_openTime ?? const TimeOfDay(hour: 9, minute: 0)) : (_closeTime ?? const TimeOfDay(hour: 22, minute: 0)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00E676), onPrimary: Colors.black, surface: Color(0xFF1E1E1E), onSurface: Colors.white)),
        child: child!,
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 15.0), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)));

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildTimePickerButton(String text, VoidCallback onTap, Color bgColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)), const Icon(Icons.access_time, color: Colors.white54)]),
      ),
    );
  }
}