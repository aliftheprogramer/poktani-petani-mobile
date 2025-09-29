import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'common/theme/color_theme.dart';
import 'pages/auth/welcome.dart';
import 'pages/container_navigator.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'pages/lahan/location_picker_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);

  // Initialize services
  final apiService = ApiService();
  final storageService = StorageService();
  apiService.init();
  await storageService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agritrack App',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      theme: appTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const WelcomePage(),
        '/home': (context) => const ContainerNavigator(),
        '/location-picker': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          double? lat;
          double? lng;
          if (args is Map) {
            final a = args;
            final latRaw = a['lat'];
            final lngRaw = a['lng'];
            if (latRaw is num) lat = latRaw.toDouble();
            if (lngRaw is num) lng = lngRaw.toDouble();
          }
          return LocationPickerPage(initialLat: lat, initialLng: lng);
        },
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final StorageService _storageService = StorageService();
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    setState(() {
      _isLoggedIn = _storageService.isLoggedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isLoggedIn! ? const ContainerNavigator() : const WelcomePage();
  }
}
