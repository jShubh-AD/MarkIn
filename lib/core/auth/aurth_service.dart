import 'package:attendence/Homepage/student_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService{

  final FirebaseAuth fireBaseAuth =FirebaseAuth.instance;

  User? get currentUser => fireBaseAuth.currentUser;

  Stream<User?> get authStateChange => fireBaseAuth.authStateChanges();

  Future< UserCredential> signIn({
    required String email,
    required String password
  }) async{
    final credentials = await fireBaseAuth
        .signInWithEmailAndPassword(
        email: email,
        password: password
    );

    return credentials;
  }

  Future<void> logOut()async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
    await fireBaseAuth.signOut();
  }

}