import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerService {
  static final _db = FirebaseFirestore.instance;

  // Create or update owner record
  static Future<void> saveOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ownerRef = _db.collection("owners").doc(user.uid);

    final doc = await ownerRef.get();

    if (!doc.exists) {
      await ownerRef.set({
        "ownerId": user.uid,
        "name": user.displayName ?? "",
        "email": user.email ?? "",
        "phone": user.phoneNumber ?? "",
        "turfsOwned": [],
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
