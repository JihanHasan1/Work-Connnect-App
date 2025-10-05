import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isTeamLeader => _currentUser?.role == 'team_leader' || isAdmin;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username');

      if (savedUsername != null && _auth.currentUser != null) {
        await _loadUserData(_auth.currentUser!.uid);
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Admin login
      if (username == 'admin' && password == 'admin') {
        final userCred = await _auth.signInAnonymously();
        _currentUser = UserModel(
          uid: userCred.user!.uid,
          username: 'admin',
          role: 'admin',
          displayName: 'Administrator',
          createdAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('role', 'admin');

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Regular user login
      final userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'Username not found';
      }

      final userData = userQuery.docs.first;
      final storedPassword = userData.data()['password'];

      if (storedPassword != password) {
        throw 'Invalid password';
      }

      final userCred = await _auth.signInAnonymously();
      await _firestore.collection('users').doc(userCred.user!.uid).set({
        ...userData.data(),
        'lastLogin': DateTime.now().toIso8601String(),
      });

      _currentUser = UserModel.fromMap(userData.data(), userCred.user!.uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('role', _currentUser!.role);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
    notifyListeners();
  }
}
