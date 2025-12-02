// lib/screens/auth/owner_login_screen.dart

import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/owner_service.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen>
    with SingleTickerProviderStateMixin {
  String? _loadingProvider;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Simple entry animation
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loadingProvider = "google");
    try {
      final result = await AuthService.signInWithGoogle();

      // Check if result is null (User might have cancelled the popup)
      if (result != null && mounted) {
        await OwnerService.saveOwner();
        Navigator.pushReplacementNamed(context, "/dashboard");
      } else {
        // User cancelled selection
        print("Google Sign In Cancelled by user");
      }
    } catch (e) {
      // THIS IS THE IMPORTANT PART: Print the exact error to console
      print("Google Sign-In Error Details: $e");

      // Show the specific error in toast temporarily for debugging
      if (mounted) _showToast("Error: ${e.toString()}", error: true);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  void _showToast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : const Color(0xFF00E676),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(18),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color backgroundColor = const Color(0xFF121212); // Deep Matte Black
    final Color cardColor = const Color(0xFF1E1E1E);       // Dark Grey
    final Color accentColor = const Color(0xFF00E676);     // Electric Green

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon or Logo Placeholder
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.business_center_rounded, size: 40, color: accentColor),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Rent My Turf",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Manage your business efficiently.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),

                    const SizedBox(height: 40),

                    // Google Button (Primary)
                    _authButton(
                      id: "google",
                      label: "Continue with Google",
                      icon: Icons.g_mobiledata_rounded, // or load a G-logo asset
                      onTap: _handleGoogleLogin,
                      bgColor: Colors.white,
                      textColor: Colors.black,
                      iconColor: Colors.black,
                    ),

                    const SizedBox(height: 16),

                    // Phone Button (Secondary / Outline)
                    _authButton(
                      id: "phone",
                      label: "Login with Phone",
                      icon: Icons.phone_android_rounded,
                      onTap: () => Navigator.pushNamed(context, "/phoneLogin"),
                      bgColor: Colors.transparent,
                      textColor: accentColor,
                      iconColor: accentColor,
                      isOutlined: true,
                      borderColor: accentColor.withOpacity(0.5),
                    ),

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, "/dashboard"),
                      child: Text(
                        "Skip for now",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
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
    );
  }

  Widget _authButton({
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    bool isOutlined = false,
    Color? borderColor,
  }) {
    final bool loading = _loadingProvider == id;
    final bool locked = _loadingProvider != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: isOutlined ? Border.all(color: borderColor!, width: 1.5) : null,
          ),
          child: Center(
            child: loading
                ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: isOutlined ? textColor : Colors.black,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}