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
      final savedRole = prefs.getString('role');

      debugPrint('🔍 Checking saved credentials...');
      debugPrint('Saved username: $savedUsername');
      debugPrint('Saved role: $savedRole');

      if (savedUsername != null && _auth.currentUser != null) {
        debugPrint('✅ Found saved session');

        // Restore admin session
        if (savedUsername == 'admin' && savedRole == 'admin') {
          _currentUser = UserModel(
            uid: _auth.currentUser!.uid,
            username: 'admin',
            role: 'admin',
            displayName: 'Administrator',
            createdAt: DateTime.now(),
          );
          debugPrint('✅ Admin session restored');
        } else {
          await _loadUserData(_auth.currentUser!.uid);
        }
      } else {
        debugPrint('ℹ️ No saved session found');
      }
    } catch (e) {
      debugPrint('❌ Auth init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔐 Attempting login...');
      debugPrint('Username: $username');

      // Admin login - HARDCODED
      if (username.toLowerCase() == 'admin' && password == 'admin') {
        debugPrint('✅ Admin credentials matched');

        // Sign in anonymously for Firebase
        final userCred = await _auth.signInAnonymously();
        debugPrint('✅ Firebase anonymous auth successful');

        // Create admin user
        _currentUser = UserModel(
          uid: userCred.user!.uid,
          username: 'admin',
          role: 'admin',
          displayName: 'Administrator',
          createdAt: DateTime.now(),
        );

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', 'admin');
        await prefs.setString('role', 'admin');
        debugPrint('✅ Admin session saved');

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Regular user login from Firestore
      debugPrint('🔍 Checking Firestore for user...');
      final userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint('❌ Username not found in Firestore');
        throw 'Username not found';
      }

      final userData = userQuery.docs.first;
      final storedPassword = userData.data()['password'];

      debugPrint('✅ User found in Firestore');

      if (storedPassword != password) {
        debugPrint('❌ Password incorrect');
        throw 'Invalid password';
      }

      debugPrint('✅ Password matched');

      // Sign in anonymously
      final userCred = await _auth.signInAnonymously();

      // Update user document with last login
      await _firestore.collection('users').doc(userCred.user!.uid).set({
        ...userData.data(),
        'lastLogin': DateTime.now().toIso8601String(),
      });

      _currentUser = UserModel.fromMap(userData.data(), userCred.user!.uid);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('role', _currentUser!.role);
      debugPrint('✅ User session saved');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
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
        debugPrint('✅ User data loaded: ${_currentUser?.username}');
      }
    } catch (e) {
      debugPrint('❌ Load user error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('🔓 Signing out...');
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
      debugPrint('✅ Signed out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }
}
