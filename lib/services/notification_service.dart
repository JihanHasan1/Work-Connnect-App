import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background notification: ${message.notification?.title}');
}

class FCMNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional notification permission');
    } else {
      debugPrint('❌ User declined or has not accepted notification permission');
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    String? token = await _messaging.getToken();
    debugPrint('📱 FCM Token: $token');

    // Save token to Firestore for the user
    if (token != null) {
      // You can save this token to user's document for targeted notifications
      // await saveTokenToDatabase(token);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      // Update token in database
      // await saveTokenToDatabase(newToken);
    });

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Initialize local notifications for Android
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Local notification tapped: ${response.payload}');
        // Handle notification tap
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'team_messages', // id
      'Team Messages', // name
      description: 'Notifications for team chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground notification: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Show notification when app is in foreground
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'team_messages',
            'Team Messages',
            channelDescription: 'Notifications for team chat messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF1E293B),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');

    // Extract team ID from notification data
    String? teamId = message.data['teamId'];

    if (teamId != null) {
      // Navigate to team chat
      // You'll need to implement navigation logic based on your app structure
      debugPrint('📱 Navigating to team: $teamId');
    }
  }

  // Send notification to team members
  static Future<void> sendTeamMessageNotification({
    required String teamId,
    required String teamName,
    required String senderName,
    required String messageContent,
    required List<String> memberIds,
  }) async {
    try {
      // Get FCM tokens for all team members
      final tokens = await _getTokensForUsers(memberIds);

      if (tokens.isEmpty) {
        debugPrint('⚠️ No FCM tokens found for team members');
        return;
      }

      // Prepare notification data
      final notification = {
        'title': teamName,
        'body': '$senderName: $messageContent',
        'data': {
          'type': 'team_message',
          'teamId': teamId,
          'teamName': teamName,
        },
      };

      debugPrint('📤 Sending notification to ${tokens.length} devices');

      // In production, you would call your backend API to send notifications
      // via Firebase Admin SDK. For now, we'll just log it.
      debugPrint('Notification payload: $notification');

      // TODO: Implement backend API call to send FCM notifications
      // await _sendNotificationViaBackend(tokens, notification);
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // Get FCM tokens for users
  static Future<List<String>> _getTokensForUsers(List<String> userIds) async {
    List<String> tokens = [];

    try {
      for (String userId in userIds) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          String? token = data?['fcmToken'];
          if (token != null && token.isNotEmpty) {
            tokens.add(token);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting tokens: $e');
    }

    return tokens;
  }

  // Save FCM token to user document
  static Future<void> saveTokenToDatabase(String token, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ FCM token saved to database');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  // Subscribe to team notifications
  static Future<void> subscribeToTeamNotifications(String teamId) async {
    try {
      await _messaging.subscribeToTopic('team_$teamId');
      debugPrint('✅ Subscribed to team_$teamId notifications');
    } catch (e) {
      debugPrint('❌ Error subscribing to team notifications: $e');
    }
  }

  // Unsubscribe from team notifications
  static Future<void> unsubscribeFromTeamNotifications(String teamId) async {
    try {
      await _messaging.unsubscribeFromTopic('team_$teamId');
      debugPrint('✅ Unsubscribed from team_$teamId notifications');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from team notifications: $e');
    }
  }
}
