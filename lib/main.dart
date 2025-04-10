// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'services/background_service.dart';
// import 'providers/expense_provider.dart';
// import 'screens/home_page.dart';
// import 'screens/overlay_screen.dart';
// import 'services/overlay_service.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize background service
//   await initializeBackgroundService();
//
//   // Initialize overlay service
//   await OverlayService.initialize();
//
//   runApp(const MyApp());
// }
//
// // Overlay entry point
// @pragma('vm:entry-point')
// void overlayMain() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(
//     const MaterialApp(
//       title: 'Perny Expense Tracker',
//       debugShowCheckedModeBanner: false,
//       home: OverlayScreen(),
//     ),
//   );
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     _checkAndStartBackgroundService();
//   }
//
//   Future<void> _checkAndStartBackgroundService() async {
//     try {
//       final isRunning = await BackgroundServiceManager.isServiceRunning();
//       if (!isRunning) {
//         await BackgroundServiceManager.startService();
//       }
//     } catch (e) {
//       debugPrint("Error starting background service: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => ExpenseProvider(),
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Expense Tracker',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           useMaterial3: true,
//           scaffoldBackgroundColor: Colors.white,
//           dividerTheme: const DividerThemeData(
//             thickness: 0.5,
//             color: Color(0xFFEEEEEE),
//           ),
//         ),
//         home: const HomePage(),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/background_service.dart';
import 'providers/expense_provider.dart';
import 'screens/home_page.dart';
import 'screens/overlay_screen.dart';
import 'services/overlay_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'background_tasks.dart'; // Import the new background task manager
import 'utils/logger.dart'; // Import logger

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.log("App starting..."); // Use your logger

  // Initialize background service configuration (does not start it yet)
  // This sets up the channel, etc.
  await initializeBackgroundService();
  AppLogger.log("Background service configuration initialized.");

  // Initialize overlay service
  await OverlayService.initialize();
  AppLogger.log("Overlay service initialized.");

  // Initialize and schedule WorkManager tasks *after* services are configured
  // This should ideally happen even if the app isn't fully running,
  // hence the top-level callbackDispatcher.
  await BackgroundTaskManager.initializeAndScheduleWork();
  AppLogger.log("WorkManager initialized and tasks scheduled.");

  runApp(const MyApp());
}

// Overlay entry point
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      title: 'Perny Expense Tracker',
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Check and potentially start the service when the app UI loads.
    // WorkManager handles the long-term persistence.
    _checkAndStartBackgroundServiceOnAppLoad();
  }

  Future<void> _checkAndStartBackgroundServiceOnAppLoad() async {
    try {
      final isRunning = await BackgroundServiceManager.isServiceRunning();
      AppLogger.log("App Load Check: Service running? $isRunning");
      if (!isRunning) {
        AppLogger.log("App Load: Service not running, starting...");
        await BackgroundServiceManager.startService();
      }
      // Optionally schedule an immediate WorkManager check if needed
      // await BackgroundTaskManager.scheduleOneOffTask();
    } catch (e) {
      AppLogger.error("Error starting background service on app load: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          dividerTheme: const DividerThemeData(
            thickness: 0.5,
            color: Color(0xFFEEEEEE),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
