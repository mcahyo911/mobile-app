import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsAppSekretariat() async {
    final Uri waUri = Uri.parse(
      'https://wa.me/6289602080600?text=Assalamu%27alaikum%20Admin%20Sekretariat%20PPM%20Al-Ajwah%2C%20saya%20mengalami%20kendala%20akun%20pada%20aplikasi.',
    );

    try {
      if (!await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp. Silakan hubungi 0896-0208-0600.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka WhatsApp. Silakan hubungi 0896-0208-0600.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoleRouterScreen(user: user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = ApiClient.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: const Color(0xFF93000A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Palet warna dari konfigurasi Tailwind Stitch (Otomatis Dark & Light)
    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBgColor = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);
    
    // Aksen Identitas PPM Al-Ajwah dari Stitch
    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Header Logo dengan Sacred Ring Glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Backdrop Pulse Glow
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryCyan.withValues(alpha: isDark ? 0.15 : 0.08),
                        ),
                      ),
                      // Outer Sacred Ring
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1A211C) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo_ppm.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.mosque_rounded,
                              size: 48,
                              color: primaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App Title
                  Text(
                    'PPM AL - AJWAH',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Sistem Informasi Akademik & Kepesantrenan Mahasiswa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Floating Card Form
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: outlineColor.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: primaryContainer.withValues(alpha: isDark ? 0.05 : 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card Heading
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Masuk ke Akun',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: onSurface,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.mosque_rounded,
                                    size: 22,
                                    color: secondaryGold,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Silakan masukkan kredensial resmi pesantren Anda.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Label Username
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 16, color: primaryCyan),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Username',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Input Field Username
                              TextFormField(
                                controller: _usernameController,
                                style: TextStyle(color: onSurface, fontSize: 14),
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: inputBgColor,
                                  hintText: 'Gunakan Nama Panggilan , Contoh: Cahyo',
                                  hintStyle: TextStyle(
                                    color: onSurfaceVariant.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  prefixIcon: const Icon(Icons.badge_outlined, color: primaryCyan, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: primaryCyan, width: 1.5),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Username wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Label Password
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 16, color: primaryCyan),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Kata Sandi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Input Field Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: onSurface, fontSize: 14),
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: inputBgColor,
                                  hintText: 'Masukkan kata sandi akun',
                                  hintStyle: TextStyle(
                                    color: onSurfaceVariant.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  prefixIcon: const Icon(Icons.key_outlined, color: primaryCyan, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: primaryCyan, width: 1.5),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Kata sandi wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Row: Ingat Saya & Lupa Sandi Direct WhatsApp
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: primaryContainer,
                                          checkColor: Colors.black,
                                          side: BorderSide(color: outlineColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ingat saya',
                                        style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: _openWhatsAppSekretariat,
                                    child: const Text(
                                      'Lupa Sandi?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: secondaryGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Primary Gradient Submit Button
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF12B3B6), Color(0xFF00696B)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryContainer.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'MASUK',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Footer Info & Bantuan Direct WhatsApp
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Kendala akun? Hubungi ',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: _openWhatsAppSekretariat,
                        child: const Text(
                          'Sekretariat PPM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryGold,
                            decoration: TextDecoration.underline,
                            decorationColor: secondaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}