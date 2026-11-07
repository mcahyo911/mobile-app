import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../guru/guru_dashboard_screen.dart';
import 'santri_presensi_tab.dart';
import 'santri_materi_tab.dart';
import 'santri_pelanggaran_tab.dart';
import 'santri_profile_tab.dart';

class SantriDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SantriDashboardScreen({super.key, required this.user});

  @override
  State<SantriDashboardScreen> createState() => _SantriDashboardScreenState();
}

class _SantriDashboardScreenState extends State<SantriDashboardScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  late Map<String, dynamic> _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
  }

  void _updateLocalUserData(Map<String, dynamic> updatedProfile) {
    setState(() {
      _currentUser['santri_profile'] = updatedProfile;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color headerColor = isDark ? const Color(0xFF0E1510) : Colors.white;
    final Color navBg = isDark ? const Color(0xFF0E1510) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color borderColor = isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.06);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    final bool isAsistenGuru = _currentUser['is_asisten_guru'] == true;
    final String statusKeaktifan = _currentUser['status_keaktifan'] ?? 'aktif';
    final String namaLengkap =
        _currentUser['santri_profile']?['nama_lengkap'] ??
            _currentUser['username'] ??
            'Santri';
    final String? fotoProfil = _currentUser['santri_profile']?['foto_profil_webp'];
    final String initial = namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : 'S';

    final List<Widget> tabs = [
      SantriPresensiTab(user: _currentUser),
      SantriMateriTab(user: _currentUser),
      SantriPelanggaranTab(user: _currentUser),
      SantriProfileTab(
        user: _currentUser,
        onProfileUpdated: _updateLocalUserData,
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Foto Profil Santri Kiri Atas dengan Ring Aksen Cyan
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryCyan.withValues(alpha: 0.25),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryContainer,
                      backgroundImage: (fotoProfil != null && fotoProfil.isNotEmpty)
                          ? NetworkImage('${ApiClient.storageBaseUrl}$fotoProfil')
                          : null,
                      child: (fotoProfil == null || fotoProfil.isEmpty)
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Informasi Header Nama Santri
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PPM Al-Ajwah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          '$namaLengkap (Santri Mahasiswa)',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Tombol Switch Mode Asisten
                  if (isAsistenGuru && statusKeaktifan == 'aktif')
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A4A01),
                          foregroundColor: secondaryGold,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: secondaryGold.withValues(alpha: 0.4)),
                          ),
                        ),
                        icon: const Icon(Icons.co_present_rounded, size: 15),
                        label: const Text(
                          'Asisten',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GuruDashboardScreen(
                                user: _currentUser,
                                isFromAsistenMode: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Tombol Logout
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Keluar',
                    icon: Icon(Icons.logout_rounded, color: onSurfaceVariant),
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (statusKeaktifan != 'aktif')
            Container(
              width: double.infinity,
              color: Colors.amber.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Status: ${statusKeaktifan.toUpperCase()} • Bebas kewajiban presensi dan target materi harian.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: primaryContainer.withValues(alpha: 0.2),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.qr_code_scanner_rounded, color: primaryCyan),
              label: 'Presensi & Izin',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.menu_book_rounded, color: primaryCyan),
              label: 'Materi Kitab',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.shield_rounded, color: primaryCyan),
              label: 'Pengaduan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.person_rounded, color: primaryCyan),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}