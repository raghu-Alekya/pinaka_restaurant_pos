// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/foundation.dart';
// //
// // class FirebaseNotificationService {
// //   FirebaseNotificationService._();
// //
// //   static final FirebaseNotificationService instance =
// //   FirebaseNotificationService._();
// //
// //   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
// //
// //   /// Call this once when the application starts.
// //   Future<void> initialize() async {
// //     // Request notification permission.
// //     final settings = await _messaging.requestPermission(
// //       alert: true,
// //       badge: true,
// //       sound: true,
// //       announcement: false,
// //       carPlay: false,
// //       criticalAlert: false,
// //       provisional: false,
// //     );
// //
// //     debugPrint(
// //       'Notification permission: ${settings.authorizationStatus}',
// //     );
// //
// //     // Get FCM token.
// //     final token = await _messaging.getToken();
// //
// //     debugPrint('=================================');
// //     debugPrint('FCM TOKEN: $token');
// //     debugPrint('=================================');
// //
// //     // Token can change in the future.
// //     _messaging.onTokenRefresh.listen((newToken) {
// //       debugPrint('FCM TOKEN REFRESHED: $newToken');
// //
// //       // TODO:
// //       // Send newToken to your backend if required.
// //     });
// //
// //     // Foreground notification.
// //     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
// //       debugPrint('FCM FOREGROUND MESSAGE');
// //
// //       debugPrint('Title: ${message.notification?.title}');
// //       debugPrint('Body: ${message.notification?.body}');
// //       debugPrint('Data: ${message.data}');
// //     });
// //
// //     // App opened by tapping notification while in background.
// //     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
// //       debugPrint('FCM NOTIFICATION CLICKED');
// //
// //       debugPrint('Title: ${message.notification?.title}');
// //       debugPrint('Body: ${message.notification?.body}');
// //       debugPrint('Data: ${message.data}');
// //
// //       _handleNotificationTap(message);
// //     });
// //
// //     // App opened from terminated state by tapping notification.
// //     final initialMessage = await _messaging.getInitialMessage();
// //
// //     if (initialMessage != null) {
// //       debugPrint('FCM APP OPENED FROM TERMINATED STATE');
// //
// //       debugPrint('Title: ${initialMessage.notification?.title}');
// //       debugPrint('Body: ${initialMessage.notification?.body}');
// //       debugPrint('Data: ${initialMessage.data}');
// //
// //       _handleNotificationTap(initialMessage);
// //     }
// //   }
// //
// //   void _handleNotificationTap(RemoteMessage message) {
// //     final data = message.data;
// //
// //     debugPrint('Notification data: $data');
// //
// //     // Example:
// //     //
// //     // final type = data['type'];
// //     // final orderId = data['orderId'];
// //     //
// //     // Based on type/orderId you can later navigate
// //     // to a particular screen.
// //   }
// // }
// //
// // /// IMPORTANT:
// // /// This function must be outside the class.
// // ///
// // /// It runs in a separate isolate when a background FCM
// // /// message is received.
// // @pragma('vm:entry-point')
// // Future<void> firebaseMessagingBackgroundHandler(
// //     RemoteMessage message,
// //     ) async {
// //   debugPrint('FCM BACKGROUND MESSAGE');
// //
// //   debugPrint('Message ID: ${message.messageId}');
// //   debugPrint('Title: ${message.notification?.title}');
// //   debugPrint('Body: ${message.notification?.body}');
// //   debugPrint('Data: ${message.data}');
// // }
//
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
//
// class FirebaseNotificationService {
//   FirebaseNotificationService._();
//
//   static final FirebaseNotificationService instance =
//   FirebaseNotificationService._();
//
//   Future<void> initialize() async {
//     // Firebase MUST already be initialized before this method is called.
//     final FirebaseMessaging messaging = FirebaseMessaging.instance;
//
//     // Request notification permission.
//     final settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     debugPrint(
//       'Notification permission: ${settings.authorizationStatus}',
//     );
//
//     // Get FCM token.
//     final token = await messaging.getToken();
//
//     debugPrint('======================================');
//     debugPrint('FCM TOKEN: $token');
//     debugPrint('======================================');
//
//     // Token refresh.
//     messaging.onTokenRefresh.listen((newToken) {
//       debugPrint('FCM TOKEN REFRESHED: $newToken');
//
//       // Send newToken to your backend here if required.
//     });
//
//     // FOREGROUND
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint('======================================');
//       debugPrint('FCM FOREGROUND MESSAGE');
//       debugPrint('Title: ${message.notification?.title}');
//       debugPrint('Body: ${message.notification?.body}');
//       debugPrint('Data: ${message.data}');
//       debugPrint('======================================');
//
//       // Show local notification here.
//     });
//
//     // BACKGROUND -> user taps notification.
//     FirebaseMessaging.onMessageOpenedApp.listen(
//           (RemoteMessage message) {
//         debugPrint('======================================');
//         debugPrint('FCM NOTIFICATION TAPPED');
//         debugPrint('Title: ${message.notification?.title}');
//         debugPrint('Body: ${message.notification?.body}');
//         debugPrint('Data: ${message.data}');
//         debugPrint('======================================');
//
//         _handleNotificationTap(message);
//       },
//     );
//
//     // TERMINATED -> user taps notification.
//     final RemoteMessage? initialMessage =
//     await messaging.getInitialMessage();
//
//     if (initialMessage != null) {
//       debugPrint('======================================');
//       debugPrint('FCM APP OPENED FROM TERMINATED STATE');
//       debugPrint('Title: ${initialMessage.notification?.title}');
//       debugPrint('Body: ${initialMessage.notification?.body}');
//       debugPrint('Data: ${initialMessage.data}');
//       debugPrint('======================================');
//
//       _handleNotificationTap(initialMessage);
//     }
//   }
//
//   void _handleNotificationTap(RemoteMessage message) {
//     final data = message.data;
//
//     debugPrint('Notification tap data: $data');
//
//     // Example:
//     //
//     // final type = data['type'];
//     // final orderId = data['orderId'];
//     //
//     // Navigate based on your notification type.
//   }
// }
//
//
// /// Background FCM handler.
// ///
// /// IMPORTANT:
// /// This must be a top-level function.
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(
//     RemoteMessage message,
//     ) async {
//   await Firebase.initializeApp();
//
//   debugPrint('======================================');
//   debugPrint('FCM BACKGROUND MESSAGE');
//   debugPrint('Title: ${message.notification?.title}');
//   debugPrint('Body: ${message.notification?.body}');
//   debugPrint('Data: ${message.data}');
//   debugPrint('======================================');
// }
