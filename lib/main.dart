import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await LocalNotifications.instance.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final api = ApiService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(api),
        ),
      ],
      child: const ListePartyApp(),
    ),
  );
}

class ListePartyApp extends StatelessWidget {
  const ListePartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Config.siteName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
