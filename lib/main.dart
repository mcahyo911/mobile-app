import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/santri/santri_dashboard_screen.dart';
import 'screens/guru/guru_dashboard_screen.dart';
import 'screens/pengurus/pengurus_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PpmAlAjwahApp());
}

class PpmAlAjwahApp extends StatelessWidget {
  const PpmAlAjwahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PPM Al-Ajwah',
      debugShowCheckedModeBanner: false,
      
      // Mengikuti pengaturan mode gelap/terang bawaan sistem HP secara otomatis
      themeMode: ThemeMode.system,

      // ================= TEMA TERANG (LIGHT THEME) =================
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFD4AF37),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),

      // ================= TEMA GELAP (DARK THEME) =================
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFD4AF37),
          surface: const Color(0xFF1E1E1E),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade800),
          ),
        ),
      ),
      
      home: const AuthCheckScreen(),
    );
  }
}

/// Layar Splash & Pengecekan Sesi dengan Animasi Logo PPM
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();

    _checkSession();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final savedUser = await _authService.getSavedUser();
    if (!mounted) return;

    if (savedUser != null) {
      try {
        final freshUser = await _authService.getMe();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RoleRouterScreen(user: freshUser)),
        );
      } catch (_) {
        final stillHasUser = await _authService.getSavedUser();
        if (!mounted) return;
        if (stillHasUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => RoleRouterScreen(user: stillHasUser)),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_ppm.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.mosque_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PPM AL-AJWAH',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sistem Informasi Akademik PPM Al-Ajwah',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Router yang mengarahkan ke dashboard masing-masing role
class RoleRouterScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const RoleRouterScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String role = user['role'] ?? 'santri';

    switch (role) {
      case 'admin':
        return AdminDashboardScreen(user: user);
      case 'pengurus':
        return PengurusDashboardScreen(user: user);
      case 'guru':
        return GuruDashboardScreen(user: user);
      case 'santri':
      default:
        return SantriDashboardScreen(user: user);
    }
  }
}