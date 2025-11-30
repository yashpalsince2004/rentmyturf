import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rentmyturf/screens/dashboard/owner_dashboard.dart';
import 'package:rentmyturf/screens/login/owner_login_screen.dart';
import 'package:rentmyturf/screens/login/owner_otp_screen.dart';
import 'package:rentmyturf/screens/login/owner_phone_login_screen.dart';
import 'package:rentmyturf/screens/turf/add_turf_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
      routes: {
        "/login": (context) => const OwnerLoginScreen(),
        "/phoneLogin": (context) => const OwnerPhoneLoginScreen(),
        "/otp": (context) => OwnerOtpScreen(verificationId: ""),
        "/dashboard": (context) => const OwnerDashboard(),
        "/addTurf": (context) => const AddTurfScreen(),
      },
    );
  }
}
