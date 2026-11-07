import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/excel_exporter_helper.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class GuruDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isFromAsistenMode;

  const GuruDashboardScreen({
    super.key,
    required this.user,
    this.isFromAsistenMode = false,
  });

  @override
  State<GuruDashboardScreen> createState() => _GuruDashboardScreenState();
}

class _GuruDashboardScreenState extends State<GuruDashboardScreen> {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();
  int _currentIndex = 0;
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic> get _user => _currentUser ?? widget.user;

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /// Dialog Ubah Profil Guru (Username, Password, dan Jenis Guru)
  Future<void> _showEditGuruProfileDialog() async {
    final usernameCtrl = TextEditingController(text: _user['username'] ?? '');
    final passwordCtrl = TextEditingController();
    
    String jenisGuru = _user['jenis_guru'] ?? 
        _user['guru_profile']?['jenis_guru'] ?? 
        'tetap';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
        final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
        final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
        final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
        const Color primaryCyan = Color(0xFF53D9DC);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts, color: primaryCyan, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Profil Dewan Guru',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubah username login, perbarui kata sandi, dan tetapkan status jenis penugasan guru.',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: usernameCtrl,
                        style: TextStyle(color: onSurface, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          labelText: 'Username (Login)',
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        style: TextStyle(color: onSurface, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          labelText: 'Password Baru',
                          hintText: 'Kosongkan jika tidak ganti',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: ['tetap', 'terbang'].contains(jenisGuru) ? jenisGuru : 'tetap',
                        dropdownColor: cardColor,
                        style: TextStyle(color: onSurface, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          labelText: 'Jenis Guru',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'tetap',
                            child: Text(
                              'Guru Tetap (Mukim)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'terbang',
                            child: Text(
                              'Guru Terbang (Tugasan)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (v) => setStateDialog(() => jenisGuru = v ?? 'tetap'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: onSurfaceVariant, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B3B6),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (usernameCtrl.text.trim().isEmpty) return;
                          setStateDialog(() => isSaving = true);
                          try {
                            final Map<String, dynamic> payload = {
                              'username': usernameCtrl.text.trim(),
                              'jenis_guru': jenisGuru,
                            };
                            if (passwordCtrl.text.trim().isNotEmpty) {
                              payload['password'] = passwordCtrl.text.trim();
                            }

                            final res = await _apiClient.dio.post('/profile', data: payload);

                            setState(() {
                              _currentUser ??= Map<String, dynamic>.from(widget.user);
                              _currentUser!['username'] = usernameCtrl.text.trim();
                              _currentUser!['jenis_guru'] = jenisGuru;
                              if (_currentUser!['guru_profile'] is Map) {
                                _currentUser!['guru_profile']['jenis_guru'] = jenisGuru;
                              }
                            });

                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.data['message'] ?? 'Profil Guru berhasil diperbarui!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ApiClient.getErrorMessage(e))),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Simpan Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color headerColor = isDark ? const Color(0xFF0E1510) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    final bool isPureGuruOrAdmin = !widget.isFromAsistenMode &&
        (_user['role'] == 'guru' || _user['role'] == 'admin');

    final List<Widget> pages = [
      const _GuruPresensiTab(),
      const _GuruMateriTab(),
      const _GuruIzinKeluarJamMalamTab(),
      if (isPureGuruOrAdmin) const _GuruPelanggaranDanAsistenTab(),
    ];

    final String initial = (_user['username'] ?? 'G').toString().substring(0, 1).toUpperCase();
    final String jenisGuru = _user['jenis_guru'] ?? _user['guru_profile']?['jenis_guru'] ?? 'tetap';
    final String jenisGuruLabel = jenisGuru == 'terbang' ? 'Guru Terbang' : 'Guru Tetap';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.isFromAsistenMode ? null : _showEditGuruProfileDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isFromAsistenMode ? const Color(0xFF0D47A1) : primaryContainer,
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: jenisGuru == 'terbang' ? secondaryGold : primaryCyan,
                                    border: Border.all(color: headerColor, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.isFromAsistenMode ? 'Mode Asisten Guru' : 'Dashboard Dewan Guru',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: onSurface,
                                    ),
                                  ),
                                  if (!widget.isFromAsistenMode) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit_note_rounded, size: 16, color: onSurfaceVariant),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: jenisGuru == 'terbang' ? secondaryGold : primaryCyan,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_user['username']} • $jenisGuruLabel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.isFromAsistenMode)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF242C26) : const Color(0xFFE8F0EA),
                        foregroundColor: secondaryGold,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('SANTRI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  else
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: _handleLogout,
                      icon: Icon(Icons.logout_rounded, color: onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1510) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: primaryContainer.withValues(alpha: 0.2),
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.calendar_month, color: primaryCyan),
              label: 'Presensi',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.auto_stories, color: primaryCyan),
              label: 'Target',
            ),
            NavigationDestination(
              icon: Icon(Icons.nightlight_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.nightlight_round, color: primaryCyan),
              label: 'Jam Malam',
            ),
            if (isPureGuruOrAdmin)
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined, color: onSurfaceVariant),
                selectedIcon: const Icon(Icons.admin_panel_settings, color: primaryCyan),
                label: 'Asisten',
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER KOMPONEN: PARSER & DISPLAY ALASAN + BADGE GPS GOOGLE MAPS
// ============================================================================
Widget _buildAlasanWithGpsWidget(BuildContext context, String labelJudul, String rawText) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  String textUtama = rawText;
  String? gpsInfo;
  String? lat;
  String? lng;

  if (rawText.contains('[Lokasi GPS')) {
    final parts = rawText.split(RegExp(r'\[Lokasi GPS[^:]*:'));
    textUtama = parts[0].trim();
    if (parts.length > 1) {
      gpsInfo = parts[1].replaceAll(']', '').trim();
      final regexCoord = RegExp(r'\(([-0-9\.]+),\s*([-0-9\.]+)\)');
      final match = regexCoord.firstMatch(gpsInfo);
      if (match != null) {
        lat = match.group(1);
        lng = match.group(2);
      }
    }
  }

  Future<void> openGoogleMaps() async {
    if (lat == null || lng == null) return;
    final Uri nativeMapUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(Lokasi Santri)');
    final Uri webMapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(nativeMapUri)) {
        await launchUrl(nativeMapUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webMapUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webMapUri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {}
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$labelJudul: $textUtama',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D),
        ),
      ),
      if (gpsInfo != null) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF09100B) : const Color(0xFFE8F2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF3C4949) : const Color(0xFFB4D8D8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF53D9DC)),
                  SizedBox(width: 4),
                  Text(
                    'Lokasi GPS Santri Saat Izin:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF53D9DC)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                gpsInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFFBBC9C9) : const Color(0xFF2B3A32),
                ),
              ),
              if (lat != null && lng != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: openGoogleMaps,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B3B6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF53D9DC).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, size: 14, color: Color(0xFF53D9DC)),
                        SizedBox(width: 6),
                        Text(
                          'Buka Titik di Google Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF53D9DC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

// ============================================================================
// TAB 1: PRESENSI, FILTER KATEGORI, EKSPOR EXCEL & TOKEN 60 DETIK
// ============================================================================
class _GuruPresensiTab extends StatefulWidget {
  const _GuruPresensiTab();

  @override
  State<_GuruPresensiTab> createState() => _GuruPresensiTabState();
}

class _GuruPresensiTabState extends State<_GuruPresensiTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _filterKategori;
  String _selectedBulan = DateFormat('MM').format(DateTime.now());
  final String _selectedTahun = DateFormat('yyyy').format(DateTime.now());
  List<dynamic> _sessions = [];

  final Map<String, String> _kategoriLabels = {
    'pengajian_subuh': 'Pengajian Subuh',
    'pengajian_malam': 'Pengajian Malam',
    'pengajian_sambung': 'Pengajian Sambung',
    'nasehat_pengurus': 'Nasehat Pengurus',
    'nasehat_santri': 'Nasehat Santri',
    'apel_sholat_malam': 'Apel Sholat Malam',
  };

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  String _extractLocalDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final String str = rawDate.toString();
    if (str.contains('T')) {
      final DateTime? parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('yyyy-MM-dd').format(parsed.toLocal());
      }
    }
    return str.split(' ').first;
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        '/presensi/sessions',
        queryParameters: _filterKategori != null ? {'kategori': _filterKategori} : null,
      );
      setState(() {
        _sessions = res.data['data']['data'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.getErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSessionFormDialog({Map<String, dynamic>? existingSession}) async {
    final bool isEdit = existingSession != null;
    String selectedKategori = existingSession?['kategori'] ?? 'pengajian_subuh';

    DateTime selectedDate = DateTime.now();
    if (isEdit && existingSession['tanggal'] != null) {
      final localDateStr = _extractLocalDate(existingSession['tanggal']);
      selectedDate = DateTime.tryParse(localDateStr) ?? DateTime.now();
    }

    String initMulai = existingSession?['waktu_mulai']?.toString() ?? '05:30';
    if (initMulai.length > 5) initMulai = initMulai.substring(0, 5);
    String initSelesai = existingSession?['waktu_selesai']?.toString() ?? '06:00';
    if (initSelesai.length > 5) initSelesai = initSelesai.substring(0, 5);

    final mulaiCtrl = TextEditingController(text: initMulai);
    final selesaiCtrl = TextEditingController(text: initSelesai);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Sesi Presensi' : 'Buka Sesi Presensi Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedKategori,
                    decoration: const InputDecoration(labelText: 'Kategori Kegiatan', border: OutlineInputBorder()),
                    items: _kategoriLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      setStateDialog(() {
                        selectedKategori = v ?? 'pengajian_subuh';
                        if (!isEdit) {
                          if (selectedKategori == 'pengajian_subuh') {
                            mulaiCtrl.text = '05:30';
                            selesaiCtrl.text = '06:00';
                          } else if (selectedKategori == 'pengajian_malam') {
                            mulaiCtrl.text = '20:00';
                            selesaiCtrl.text = '21:30';
                          } else if (selectedKategori == 'nasehat_santri') {
                            mulaiCtrl.text = '08:00';
                            selesaiCtrl.text = '09:00';
                          } else if (selectedKategori == 'apel_sholat_malam') {
                            mulaiCtrl.text = '03:30';
                            selesaiCtrl.text = '04:30';
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal Sesi'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setStateDialog(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mulaiCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Mulai', border: OutlineInputBorder()),
                          onTap: () async {
                            final parts = mulaiCtrl.text.split(':');
                            final initTime = parts.length >= 2
                                ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0)
                                : TimeOfDay.now();
                            final picked = await showTimePicker(context: context, initialTime: initTime);
                            if (picked != null) {
                              setStateDialog(() {
                                mulaiCtrl.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: selesaiCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Selesai', border: OutlineInputBorder()),
                          onTap: () async {
                            final parts = selesaiCtrl.text.split(':');
                            final initTime = parts.length >= 2
                                ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0)
                                : TimeOfDay.now();
                            final picked = await showTimePicker(context: context, initialTime: initTime);
                            if (picked != null) {
                              setStateDialog(() {
                                selesaiCtrl.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setStateDialog(() => isSaving = true);
                        final payload = {
                          'kategori': selectedKategori,
                          'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate),
                          'waktu_mulai': mulaiCtrl.text.trim(),
                          'waktu_selesai': selesaiCtrl.text.trim(),
                        };
                        try {
                          if (isEdit) {
                            await _apiClient.dio.put('/presensi/sessions/${existingSession['id']}', data: payload);
                          } else {
                            await _apiClient.dio.post('/presensi/sessions', data: payload);
                          }
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _fetchSessions();
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiClient.getErrorMessage(e))),
                          );
                        }
                      },
                child: Text(isEdit ? 'Simpan' : 'Buat Sesi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteSession(Map<String, dynamic> session, String label) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Sesi Presensi?'),
        content: Text('Hapus sesi "$label" (${_extractLocalDate(session['tanggal'])}) beserta rekapnya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _apiClient.dio.delete('/presensi/sessions/${session['id']}');
      _fetchSessions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.getErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_guru_presensi',
        backgroundColor: primaryContainer,
        foregroundColor: Colors.white,
        onPressed: () => _showSessionFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Buka Sesi Presensi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune, size: 18, color: primaryCyan),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filter Rekap & Halaqah', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: onSurface)),
                            Text('Sinkronisasi data sistem terpusat', style: TextStyle(fontSize: 10, color: onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: secondaryGold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _filterKategori,
                            hint: Text('Semua Sesi', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                            dropdownColor: cardColor,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Semua Sesi (6 Kategori)', style: TextStyle(fontSize: 12, color: onSurface)),
                              ),
                              ..._kategoriLabels.entries.map(
                                (e) => DropdownMenuItem<String?>(
                                  value: e.key,
                                  child: Text(e.value, style: TextStyle(fontSize: 12, color: onSurface)),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _filterKategori = v);
                              _fetchSessions();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedBulan,
                            dropdownColor: cardColor,
                            items: List.generate(12, (i) {
                              final m = (i + 1).toString().padLeft(2, '0');
                              return DropdownMenuItem(
                                value: m,
                                child: Text('Bulan $m', style: TextStyle(fontSize: 12, color: onSurface)),
                              );
                            }),
                            onChanged: (v) {
                              setState(() => _selectedBulan = v ?? '01');
                              _fetchSessions();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF12B3B6), Color(0xFF00696B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => ExcelExporterHelper.downloadPresensiExcel(
                      context: context,
                      bulan: _selectedBulan,
                      tahun: _selectedTahun,
                      kategori: _filterKategori,
                    ),
                    icon: const Icon(Icons.file_download, size: 18, color: Colors.white),
                    label: const Text(
                      'Ekspor Rekap (.CSV / Excel)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchSessions,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? Center(child: Text('Belum ada sesi presensi.', style: TextStyle(color: onSurfaceVariant)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final s = _sessions[index];
                            final String label = _kategoriLabels[s['kategori']] ?? s['kategori'];
                            final String tanggal = _extractLocalDate(s['tanggal']);
                            final String waktuSelesai = (s['waktu_selesai'] ?? '23:59:59').toString();
                            final String jamSelesaiFormatted =
                                waktuSelesai.length == 5 ? '$waktuSelesai:00' : waktuSelesai;
                            final DateTime? endDateTime = DateTime.tryParse('$tanggal $jamSelesaiFormatted');
                            final bool isClosed = (s['is_closed'] == true) ||
                                (endDateTime != null && DateTime.now().isAfter(endDateTime));

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isClosed
                                      ? outlineColor.withValues(alpha: 0.3)
                                      : primaryCyan.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$tanggal • ${s['waktu_mulai']} - ${s['waktu_selesai']} WITA',
                                              style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(Icons.edit_outlined, size: 18, color: onSurfaceVariant),
                                            onPressed: () => _showSessionFormDialog(existingSession: s),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                            onPressed: () => _confirmDeleteSession(s, label),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isClosed
                                                  ? Colors.red.withValues(alpha: 0.15)
                                                  : primaryCyan.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isClosed ? 'DITUTUP' : 'AKTIF',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isClosed ? Colors.redAccent : primaryCyan,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildStatBox('Hadir', '${s['total_hadir'] ?? 0}', primaryCyan, inputBg),
                                      const SizedBox(width: 6),
                                      _buildStatBox('Izin', '${s['total_izin'] ?? 0}', const Color(0xFF7AD5D7), inputBg),
                                      const SizedBox(width: 6),
                                      _buildStatBox('Sakit', '${s['total_sakit'] ?? 0}', secondaryGold, inputBg),
                                      const SizedBox(width: 6),
                                      _buildStatBox('Alpha', '${s['total_alpha'] ?? 0}', const Color(0xFFFFB4AB), inputBg),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: outlineColor.withValues(alpha: 0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => _SessionDetailRecordsScreen(
                                                  sessionId: s['id'],
                                                  title: label,
                                                ),
                                              ),
                                            ).then((_) => _fetchSessions());
                                          },
                                          icon: const Icon(Icons.how_to_reg, size: 16),
                                          label: const Text('Edit Kehadiran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      if (!isClosed) ...[
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6A4A01),
                                            foregroundColor: const Color(0xFFE9BC6C),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => _TokenProjectorScreen(
                                                  sessionId: s['id'],
                                                  title: label,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.tv, size: 16),
                                          label: const Text('Token (60s)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TOKEN PROJECTOR SCREEN
// ============================================================================
class _TokenProjectorScreen extends StatefulWidget {
  final int sessionId;
  final String title;

  const _TokenProjectorScreen({required this.sessionId, required this.title});

  @override
  State<_TokenProjectorScreen> createState() => _TokenProjectorScreenState();
}

class _TokenProjectorScreenState extends State<_TokenProjectorScreen> {
  final ApiClient _apiClient = ApiClient();
  String _currentToken = '------';
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _syncTokenFromServer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        _syncTokenFromServer();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncTokenFromServer() async {
    try {
      final res = await _apiClient.dio.get('/presensi/sessions/${widget.sessionId}/token');
      final data = res.data['data'];
      if (!mounted) return;
      setState(() {
        _currentToken = (data['token_saat_ini'] ?? '------').toString();
        _secondsRemaining = data['sisa_detik'] ?? 60;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color boxBg = isDark ? const Color(0xFF09100B) : const Color(0xFFE8F2EC);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color secondaryGold = Color(0xFFEDBF70);

    final String tokenPadded = _currentToken.padRight(6, '-').substring(0, 6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Token: ${widget.title}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A4A01).withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: secondaryGold.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.tv, size: 30, color: secondaryGold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MASUKKAN 6 DIGIT TOKEN DI HP SANTRI',
                  style: TextStyle(
                    color: primaryCyan,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Token diperbarui berkala secara otomatis',
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: outlineColor.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryCyan.withValues(alpha: isDark ? 0.08 : 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            final char = tokenPadded[i];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 48,
                              height: 64,
                              decoration: BoxDecoration(
                                color: boxBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: secondaryGold.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: secondaryGold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _secondsRemaining / 60.0,
                            minHeight: 8,
                            backgroundColor: boxBg,
                            color: primaryCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: primaryCyan),
                          const SizedBox(width: 6),
                          Text(
                            'Berganti dalam $_secondsRemaining detik',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DETAIL RECORDS KEHADIRAN SCREEN
// ============================================================================
class _SessionDetailRecordsScreen extends StatefulWidget {
  final int sessionId;
  final String title;

  const _SessionDetailRecordsScreen({required this.sessionId, required this.title});

  @override
  State<_SessionDetailRecordsScreen> createState() => _SessionDetailRecordsScreenState();
}

class _SessionDetailRecordsScreenState extends State<_SessionDetailRecordsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/presensi/sessions/${widget.sessionId}');
      if (mounted) {
        setState(() {
          _records = res.data['data']['records'] ?? [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatusManual(int recordId, String newStatus) async {
    try {
      await _apiClient.dio.put('/presensi/records/$recordId/status-manual', data: {'status': newStatus});
      _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    }
  }

  Future<void> _approveIzin(int recordId, String decision) async {
    try {
      await _apiClient.dio.patch('/presensi/records/$recordId/approve-izin', data: {'status_approval_izin': decision});
      _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return const Color(0xFF53D9DC);
      case 'izin':
        return const Color(0xFF7AD5D7);
      case 'sakit':
        return const Color(0xFFEDBF70);
      case 'alpha':
      default:
        return const Color(0xFFFFB4AB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color boxBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kehadiran: ${widget.title}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
            ),
            Text(
              '${_records.length} Santri Terdaftar',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Text('Belum ada data presensi santri.', style: TextStyle(color: onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, idx) {
                    final rec = _records[idx];
                    final santri = rec['santri'] ?? {};
                    final profile = santri['santri_profile'] ?? {};
                    final String nama = profile['nama_lengkap'] ?? santri['username'] ?? 'Santri';
                    final String kamar = profile['kamar'] ?? '-';
                    final String status = rec['status'] ?? 'alpha';
                    final String? approval = rec['status_approval_izin'];
                    final String? buktiPath = rec['bukti_izin_webp'];
                    final Color statusColor = _getStatusColor(status);

                    final String initial = nama.isNotEmpty ? nama[0].toUpperCase() : 'S';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: statusColor.withValues(alpha: 0.15),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Kamar: $kamar • @${santri['username'] ?? ''}',
                                      style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: boxBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: status,
                                    isDense: true,
                                    dropdownColor: cardColor,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'hadir', child: Text('HADIR')),
                                      DropdownMenuItem(value: 'izin', child: Text('IZIN')),
                                      DropdownMenuItem(value: 'sakit', child: Text('SAKIT')),
                                      DropdownMenuItem(value: 'alpha', child: Text('ALPHA')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) _updateStatusManual(rec['id'], val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (rec['alasan_izin'] != null) ...[
                            const SizedBox(height: 10),
                            _buildAlasanWithGpsWidget(context, 'Alasan Izin', rec['alasan_izin'].toString()),
                          ],
                          if (buktiPath != null && buktiPath.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                backgroundColor: boxBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => ExcelExporterHelper.showFullScreenImage(
                                context,
                                '${ApiClient.storageBaseUrl}$buktiPath',
                                title: 'Bukti Izin: $nama',
                              ),
                              icon: const Icon(Icons.zoom_in, size: 16),
                              label: const Text('Lihat Foto Bukti (Full Screen)', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                          if (approval == 'pending') ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _approveIzin(rec['id'], 'rejected'),
                                  child: const Text('Tolak Izin', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF12B3B6),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () => _approveIzin(rec['id'], 'approved'),
                                  child: const Text('Setujui Izin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================================
// TAB 2: TARGET MATERI HARIAN & VALIDASI FOTO KITAB SANTRI
// ============================================================================
class _GuruMateriTab extends StatefulWidget {
  const _GuruMateriTab();

  @override
  State<_GuruMateriTab> createState() => _GuruMateriTabState();
}

class _GuruMateriTabState extends State<_GuruMateriTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _targets = [];
  List<dynamic> _masterAlquran = [];
  List<dynamic> _masterHadits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final masterRes = await _apiClient.dio.get('/materi/master-data');
      final targetRes = await _apiClient.dio.get('/materi/target');
      setState(() {
        _masterAlquran = masterRes.data['data']['alquran'] ?? [];
        _masterHadits = masterRes.data['data']['hadits'] ?? [];
        _targets = targetRes.data['data']['data'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateTargetModal() async {
    String jenisMateri = 'alquran';
    int? selectedSurahId = _masterAlquran.isNotEmpty ? _masterAlquran.first['id'] : 1;
    int? selectedHaditsId = _masterHadits.isNotEmpty ? _masterHadits.first['id'] : null;

    final ayatAwalCtrl = TextEditingController(text: '1');
    final ayatAkhirCtrl = TextEditingController(text: '10');
    final halAwalCtrl = TextEditingController(text: '1');
    final barisAwalCtrl = TextEditingController(text: '1');
    final halAkhirCtrl = TextEditingController(text: '2');
    final barisAkhirCtrl = TextEditingController(text: '15');
    final catatanCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Buat Target Materi Harian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'alquran', label: Text('Al-Qur\'an')),
                      ButtonSegment(value: 'hadits', label: Text('Al-Hadits')),
                    ],
                    selected: {jenisMateri},
                    onSelectionChanged: (v) => setStateModal(() => jenisMateri = v.first),
                  ),
                  const SizedBox(height: 16),
                  if (jenisMateri == 'alquran') ...[
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedSurahId,
                      decoration: const InputDecoration(labelText: 'Pilih Surah (1-114)', border: OutlineInputBorder()),
                      items: _masterAlquran
                          .map<DropdownMenuItem<int>>(
                            (s) => DropdownMenuItem<int>(
                              value: s['id'],
                              child: Text('${s['id']}. ${s['nama_surah']} (${s['total_ayat']} Ayat)'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setStateModal(() => selectedSurahId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ayatAwalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ayat Awal', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: ayatAkhirCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ayat Akhir', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedHaditsId,
                      decoration: const InputDecoration(labelText: 'Pilih Kitab Hadits', border: OutlineInputBorder()),
                      items: _masterHadits
                          .map<DropdownMenuItem<int>>(
                            (h) => DropdownMenuItem<int>(
                              value: h['id'],
                              child: Text('${h['nama_kitab']} (Maks ${h['maksimal_halaman']} Hal)'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setStateModal(() => selectedHaditsId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: halAwalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Hal Awal', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: barisAwalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Baris Awal', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: halAkhirCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Hal Akhir', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: barisAkhirCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Baris Akhir', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan (Opsional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B3B6),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setStateModal(() => isSubmitting = true);
                            try {
                              final payload = <String, dynamic>{
                                'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                'jenis_materi': jenisMateri,
                                'catatan_materi': catatanCtrl.text.trim(),
                              };
                              if (jenisMateri == 'alquran') {
                                payload['surah_id'] = selectedSurahId;
                                payload['ayat_awal'] = int.tryParse(ayatAwalCtrl.text.trim());
                                payload['ayat_akhir'] = int.tryParse(ayatAkhirCtrl.text.trim());
                              } else {
                                payload['hadits_id'] = selectedHaditsId;
                                payload['halaman_awal'] = int.tryParse(halAwalCtrl.text.trim());
                                payload['baris_awal'] = int.tryParse(barisAwalCtrl.text.trim());
                                payload['halaman_akhir'] = int.tryParse(halAkhirCtrl.text.trim());
                                payload['baris_akhir'] = int.tryParse(barisAkhirCtrl.text.trim());
                              }
                              await _apiClient.dio.post('/materi/target', data: payload);
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              _loadData();
                            } catch (e) {
                              setStateModal(() => isSubmitting = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
                            }
                          },
                    child: const Text('SIMPAN TARGET MATERI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_guru_materi',
        backgroundColor: primaryContainer,
        foregroundColor: Colors.white,
        onPressed: _showCreateTargetModal,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Tambah Target', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: _targets.length,
                itemBuilder: (context, idx) {
                  final t = _targets[idx];
                  final String jenis = t['jenis_materi'] ?? 'alquran';
                  final String judul = jenis == 'alquran'
                      ? 'Surah ${t['surah']?['nama_surah'] ?? ''}: Ayat ${t['ayat_awal']}-${t['ayat_akhir']}'
                      : '${t['hadits']?['nama_kitab'] ?? ''}: Hal ${t['halaman_awal']}:${t['baris_awal']} s/d ${t['halaman_akhir']}:${t['baris_akhir']}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.auto_stories, size: 20, color: secondaryGold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    judul,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                                  ),
                                  Text(
                                    jenis == 'alquran' ? 'Target Al-Qur\'an' : 'Target Hadits Himpunan',
                                    style: const TextStyle(fontSize: 11, color: secondaryGold, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => _ValidasiProgresSantriScreen(
                                      targetId: t['id'],
                                      judulMateri: judul,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniBadge('Menunggu: ${t['total_menunggu'] ?? 0}', secondaryGold),
                              _buildMiniBadge('Tervalidasi: ${t['total_tervalidasi'] ?? 0}', primaryCyan),
                              _buildMiniBadge('Belum: ${t['total_belum_setor'] ?? 0}', onSurfaceVariant),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color col) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)),
      ],
    );
  }
}

// ============================================================================
// SCREEN VALIDASI PROGRES SANTRI DENGAN THUMBNAIL FOTO
// ============================================================================
class _ValidasiProgresSantriScreen extends StatefulWidget {
  final int targetId;
  final String judulMateri;

  const _ValidasiProgresSantriScreen({required this.targetId, required this.judulMateri});

  @override
  State<_ValidasiProgresSantriScreen> createState() => _ValidasiProgresSantriScreenState();
}

class _ValidasiProgresSantriScreenState extends State<_ValidasiProgresSantriScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _progresList = [];

  @override
  void initState() {
    super.initState();
    _fetchTargetDetail();
  }

  Future<void> _fetchTargetDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/materi/target/${widget.targetId}');
      setState(() {
        _progresList = res.data['data']['progres_santri'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateProgres(int progresId, String statusValidasi, {String? catatanPenolakan}) async {
    try {
      final res = await _apiClient.dio.patch(
        '/materi/progres/$progresId/validasi',
        data: {'status_validasi': statusValidasi, 'catatan_penolakan': catatanPenolakan},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data['message'] ?? 'Berhasil divalidasi!'), backgroundColor: Colors.green.shade700),
      );
      _fetchTargetDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    }
  }

  Future<void> _showRejectDialog(int progresId) async {
    final catatanCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Setoran Kitab'),
        content: TextField(
          controller: catatanCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Catatan Penolakan (Wajib)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              if (catatanCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _validateProgres(progresId, 'ditolak', catatanPenolakan: catatanCtrl.text.trim());
            },
            child: const Text('Kirim Penolakan'),
          ),
        ],
      ),
    );
  }

  List<String> _extractFotoListGuru(dynamic rawFoto) {
    if (rawFoto == null) return [];
    if (rawFoto is List) return rawFoto.map((e) => e.toString()).toList();
    final str = rawFoto.toString().trim();
    if (str.startsWith('[')) {
      try {
        final List<dynamic> parsed = jsonDecode(str);
        return parsed.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    if (str.isNotEmpty) return [str];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5),
      appBar: AppBar(title: Text(widget.judulMateri)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _progresList.length,
              itemBuilder: (context, idx) {
                final p = _progresList[idx];
                final santri = p['santri'] ?? {};
                final String nama = santri['santri_profile']?['nama_lengkap'] ?? santri['username'] ?? 'Santri';
                final String status = p['status_validasi'] ?? 'belum_setor';
                final List<String> fotoPaths = _extractFotoListGuru(p['foto_kitab_webp']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == 'tervalidasi_penuh'
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : (status == 'menunggu_validasi'
                                      ? Colors.blue.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status == 'tervalidasi_penuh'
                                    ? Colors.greenAccent
                                    : (status == 'menunggu_validasi' ? Colors.blueAccent : onSurfaceVariant),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (fotoPaths.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: fotoPaths.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final path = fotoPaths[i];
                              return GestureDetector(
                                onTap: () => ExcelExporterHelper.showFullScreenImage(
                                  context,
                                  '${ApiClient.storageBaseUrl}$path',
                                  title: 'Setoran Kitab: $nama (Hal ${i + 1})',
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '${ApiClient.storageBaseUrl}$path',
                                        height: 120,
                                        width: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 90,
                                          height: 120,
                                          color: Colors.grey.shade800,
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(4),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                      child: Text('Hal ${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showRejectDialog(p['id']),
                            child: const Text('Tolak / Revisi', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF12B3B6), foregroundColor: Colors.black),
                            onPressed: () => _validateProgres(p['id'], 'tervalidasi_penuh'),
                            child: const Text('Validasi Penuh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// TAB 3: VALIDASI IZIN, KONTROL MALAM HARIAN & REKAP JAM MALAM
// ============================================================================
class _GuruIzinKeluarJamMalamTab extends StatefulWidget {
  const _GuruIzinKeluarJamMalamTab();

  @override
  State<_GuruIzinKeluarJamMalamTab> createState() => _GuruIzinKeluarJamMalamTabState();
}

class _GuruIzinKeluarJamMalamTabState extends State<_GuruIzinKeluarJamMalamTab> {
  final ApiClient _apiClient = ApiClient();
  int _subView = 0;
  bool _isLoading = true;

  DateTime _selectedTanggalKontrol = DateTime.now();
  String _selectedBulanRekap = DateFormat('MM').format(DateTime.now());
  final String _selectedTahunRekap = DateFormat('yyyy').format(DateTime.now());

  List<dynamic> _izinList = [];
  List<dynamic> _kontrolMalamList = [];
  List<dynamic> _rekapJamMalamList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _extractLocalDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final String str = rawDate.toString();
    if (str.contains('T')) {
      final DateTime? parsed = DateTime.tryParse(str);
      if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed.toLocal());
    }
    return str.split(' ').first;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final String tglKontrol = DateFormat('yyyy-MM-dd').format(_selectedTanggalKontrol);
      final resIzin = await _apiClient.dio.get('/izin-keluar');
      final resRekap = await _apiClient.dio.get(
        '/izin-keluar/rekap',
        queryParameters: {'bulan': _selectedBulanRekap, 'tahun': _selectedTahunRekap, 'tanggal': tglKontrol},
      );

      List<dynamic> kontrolData = [];
      try {
        final resKontrol = await _apiClient.dio.get('/izin-keluar/kontrol-malam', queryParameters: {'tanggal': tglKontrol});
        kontrolData = resKontrol.data['data'] ?? [];
      } catch (_) {
        kontrolData = resRekap.data['data'] ?? [];
      }

      if (!mounted) return;
      setState(() {
        _izinList = resIzin.data['data']['data'] ?? [];
        _rekapJamMalamList = resRekap.data['data'] ?? [];
        _kontrolMalamList = kontrolData;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validasiIzinKeluar(int id, String decision) async {
    try {
      await _apiClient.dio.patch('/izin-keluar/$id/validasi', data: {'status_approval': decision});
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    }
  }

  Future<void> _catatStatusKontrolMalam(int santriId, String namaSantri, String statusKontrol) async {
    final String tgl = DateFormat('yyyy-MM-dd').format(_selectedTanggalKontrol);
    try {
      await _apiClient.dio.post(
        '/izin-keluar/kontrol-malam',
        data: {'santri_id': santriId, 'tanggal': tgl, 'status_kontrol': statusKontrol},
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;

    return Column(
      children: [
        Container(
          color: cardColor,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Validasi Izin', style: TextStyle(fontSize: 11))),
              ButtonSegment(value: 1, label: Text('Kontrol Malam', style: TextStyle(fontSize: 11))),
              ButtonSegment(value: 2, label: Text('Rekap', style: TextStyle(fontSize: 11))),
            ],
            selected: {_subView},
            onSelectionChanged: (v) => setState(() => _subView = v.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subView == 0
                    ? _buildDaftarPengajuan()
                    : _subView == 1
                        ? _buildKontrolMalamHarian()
                        : _buildRekapJamMalam(),
          ),
        ),
      ],
    );
  }

  Widget _buildDaftarPengajuan() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);

    if (_izinList.isEmpty) {
      return Center(child: Text('Belum ada pengajuan izin keluar.', style: TextStyle(color: onSurfaceVariant)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _izinList.length,
      itemBuilder: (context, idx) {
        final iz = _izinList[idx];
        final santri = iz['santri'] ?? {};
        final String nama = santri['santri_profile']?['nama_lengkap'] ?? santri['username'] ?? 'Santri';
        final String kamar = santri['santri_profile']?['kamar'] ?? '-';
        final bool lewat23 = iz['is_lewat_jam_malam'] == true;
        final String status = (iz['status_approval'] ?? 'pending').toString();
        final String? buktiPath = iz['bukti_foto_webp'];
        final String tanggal = _extractLocalDate(iz['tanggal']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lewat23 ? Colors.redAccent.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('$nama (Kamar: $kamar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface)),
                  ),
                  if (lewat23)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF93000A), borderRadius: BorderRadius.circular(4)),
                      child: const Text('LEWAT 23:00 WITA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('$tanggal | Keluar: ${iz['waktu_keluar']} • Estimasi: ${iz['estimasi_kembali']}', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
              const SizedBox(height: 8),
              _buildAlasanWithGpsWidget(context, 'Keperluan', (iz['keperluan'] ?? '').toString()),
              if (buktiPath != null && buktiPath.isNotEmpty) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => ExcelExporterHelper.showFullScreenImage(
                    context,
                    '${ApiClient.storageBaseUrl}$buktiPath',
                    title: 'Bukti Izin: $nama',
                  ),
                  icon: const Icon(Icons.zoom_in, size: 16),
                  label: const Text('Lihat Foto Bukti'),
                ),
              ],
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STATUS: ${status.toUpperCase()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
                  if (status == 'pending')
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _validasiIzinKeluar(iz['id'], 'rejected'),
                          child: const Text('Tolak', style: TextStyle(color: Colors.redAccent)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF12B3B6), foregroundColor: Colors.black),
                          onPressed: () => _validasiIzinKeluar(iz['id'], 'approved'),
                          child: const Text('Setujui'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKontrolMalamHarian() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final String tglStr = DateFormat('yyyy-MM-dd').format(_selectedTanggalKontrol);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kontrolMalamList.length,
      itemBuilder: (context, idx) {
        final s = _kontrolMalamList[idx];
        final int santriId = s['id'] ?? 0;
        final String nama = s['santri_profile']?['nama_lengkap'] ?? s['username'] ?? 'Santri';
        final String kamar = s['santri_profile']?['kamar'] ?? '-';
        final String statusMalamIni = s['status_kontrol_malam']?.toString() ?? 'di_pondok';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(statusMalamIni.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Kamar: $kamar • $tglStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Di Pondok', style: TextStyle(fontSize: 11)),
                    selected: statusMalamIni == 'di_pondok',
                    onSelected: (_) => _catatStatusKontrolMalam(santriId, nama, 'di_pondok'),
                  ),
                  ChoiceChip(
                    label: const Text('Keluar Tanpa Izin', style: TextStyle(fontSize: 11)),
                    selected: statusMalamIni == 'keluar_tanpa_izin',
                    onSelected: (_) => _catatStatusKontrolMalam(santriId, nama, 'keluar_tanpa_izin'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRekapJamMalam() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rekapJamMalamList.length,
      itemBuilder: (context, idx) {
        final s = _rekapJamMalamList[idx];
        final String nama = s['santri_profile']?['nama_lengkap'] ?? s['username'] ?? 'Santri';
        final int totalKeluar = s['total_izin_keluar'] ?? 0;
        final int totalLewat23 = s['total_lewat_jam_malam'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Total Izin: $totalKeluar x | Lewat 23:00: $totalLewat23 x'),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 4: KELOLA HAK AKSES ASISTEN GURU (LIST LENGKAP & SWITCH)
// ============================================================================
class _GuruPelanggaranDanAsistenTab extends StatefulWidget {
  const _GuruPelanggaranDanAsistenTab();

  @override
  State<_GuruPelanggaranDanAsistenTab> createState() => _GuruPelanggaranDanAsistenTabState();
}

class _GuruPelanggaranDanAsistenTabState extends State<_GuruPelanggaranDanAsistenTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _santriList = [];
  List<dynamic> _filteredSantriList = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDaftarSantri();
  }

  Future<void> _fetchDaftarSantri() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/users/santri-asisten');
      final list = res.data['data'] ?? [];
      setState(() {
        _santriList = list;
        _filterSantri(_searchCtrl.text);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSantri(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredSantriList = _santriList);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredSantriList = _santriList.where((s) {
          final nama = (s['santri_profile']?['nama_lengkap'] ?? '').toString().toLowerCase();
          final username = (s['username'] ?? '').toString().toLowerCase();
          return nama.contains(q) || username.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _toggleAsisten(int userId, bool currentStatus) async {
    final bool newStatus = !currentStatus;
    setState(() {
      final index = _santriList.indexWhere((e) => e['id'] == userId);
      if (index != -1) _santriList[index]['is_asisten_guru'] = newStatus;
      _filterSantri(_searchCtrl.text);
    });

    try {
      await _apiClient.dio.patch('/users/$userId/toggle-asisten', data: {'is_asisten_guru': newStatus});
    } catch (_) {
      _fetchDaftarSantri();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final int totalAsisten = _santriList.where((s) => s['is_asisten_guru'] == true).length;

    return RefreshIndicator(
      onRefresh: _fetchDaftarSantri,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF12B3B6), Color(0xFF00696B)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hak Akses Asisten', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Bantu presensi & simakan materi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEDBF70), borderRadius: BorderRadius.circular(20)),
                  child: Text('$totalAsisten Aktif', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterSantri,
              decoration: InputDecoration(
                hintText: 'Cari santri...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredSantriList.length,
                    itemBuilder: (context, index) {
                      final santri = _filteredSantriList[index];
                      final String nama = santri['santri_profile']?['nama_lengkap'] ?? santri['username'];
                      final bool isAsisten = santri['is_asisten_guru'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAsisten ? const Color(0xFF53D9DC).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ListTile(
                          title: Text(nama, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                          subtitle: Text('@${santri['username']}', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          trailing: Switch(
                            value: isAsisten,
                            activeColor: const Color(0xFF53D9DC),
                            onChanged: (_) => _toggleAsisten(santri['id'], isAsisten),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}