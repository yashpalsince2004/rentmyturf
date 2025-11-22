import 'package:flutter/material.dart';
import 'package:rentmyturf/screens/dashboard/owner_home_screen.dart';
import 'package:rentmyturf/screens/login/owner_phone_login_screen.dart';
import 'screens/login/owner_login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // make sure firebase_options.dart is included if needed

  runApp(const RentMyTurfApp());
}

class RentMyTurfApp extends StatelessWidget {
  const RentMyTurfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Rent My Turf",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: "/login",
      routes: {
        "/login": (context) => const OwnerLoginScreen(),
        "/phoneLogin": (context) => const OwnerPhoneLoginScreen(), // coming next
        "/dashboard": (context) => const OwnerHomeScreen(),         // after login
      },
    );
  }
}
