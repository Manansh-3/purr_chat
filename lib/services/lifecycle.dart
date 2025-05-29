import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppLifecycleReactor extends WidgetsBindingObserver {
  final String userId;

  AppLifecycleReactor(this.userId) {
    WidgetsBinding.instance.addObserver(this);
    _setUserStatus("online"); // Mark online immediately on creation
  }

  void _setUserStatus(String status) {
    FirebaseFirestore.instance.collection("users").doc(userId).update({
      "status": status,
      "lastActive": FieldValue.serverTimestamp(),
    }).catchError((e) => print("Status update error: $e"));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Lifecycle changed: $state");

    if (state == AppLifecycleState.resumed) {
      _setUserStatus("online");
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setUserStatus("offline");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
