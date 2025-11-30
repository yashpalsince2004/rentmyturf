import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../../services/owner_service.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen>
    with SingleTickerProviderStateMixin {
  String? _loadingProvider;
  StreamSubscription? _gyroStream;

  double _offsetX = 0;
  double _offsetY = 0;
  double smoothX = 0;
  double smoothY = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    const double smoothing = 0.05;

    _gyroStream = gyroscopeEvents.listen((GyroscopeEvent e) {
      double targetX = (e.y * 10).clamp(-22.0, 22.0);
      double targetY = (e.x * 10).clamp(-22.0, 22.0);

      smoothX = smoothX + (targetX - smoothX) * smoothing;
      smoothY = smoothY + (targetY - smoothY) * smoothing;

      if (mounted) {
        setState(() {
          _offsetX = smoothX;
          _offsetY = smoothY;
        });
      }
    });

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _gyroStream?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loadingProvider = "google");
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null && mounted) {
        await OwnerService.saveOwner();
        Navigator.pushReplacementNamed(context, "/dashboard");
      }
    } catch (_) {
      _showToast("Google Sign-In failed. Try again.", error: true);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  void _showToast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent.withOpacity(.8) : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(18),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 🌿 Parallax Turf Background
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(_offsetX, _offsetY),
              child: Transform.scale(
                scale: 1.07,
                child: Image.asset(
                  "assets/images/turf_bg.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 🔹 Frosted Login Card
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _glassLoginCard(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _glassLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 42, 26, 34),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(.22), width: 1.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Rent My Turf",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(.95),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Manage • Earn • Grow",
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),

              const SizedBox(height: 38),

              _authButton(
                id: "google",
                label: "Continue with Google",
                icon: Icons.g_mobiledata_rounded,
                onTap: _handleGoogleLogin,
              ),
              const SizedBox(height: 16),

              _authButton(
                id: "phone",
                label: "Login with Phone",
                icon: Icons.phone_android_rounded,
                onTap: () => Navigator.pushNamed(context, "/phoneLogin"),
              ),

              const SizedBox(height: 26),

              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, "/dashboard"),
                child: Text(
                  "Skip for now →",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
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
  }) {
    final bool loading = _loadingProvider == id;
    final bool locked = _loadingProvider != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: locked ? null : onTap,
              child: Center(
                child: loading
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
}
