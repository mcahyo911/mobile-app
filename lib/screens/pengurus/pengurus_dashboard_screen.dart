import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/excel_exporter_helper.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class PengurusDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const PengurusDashboardScreen({super.key, required this.user});

  @override
  State<PengurusDashboardScreen> createState() => _PengurusDashboardScreenState();
}

class _PengurusDashboardScreenState extends State<PengurusDashboardScreen> {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  int _currentIndex = 0;
  bool _isLoadingRekap = true;
  bool _isLoadingIzinKeluar = true;
  bool _isLoadingPelanggaran = true;

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic> get _user => _currentUser ?? widget.user;

  String? _selectedKategori;
  String _selectedBulan = DateFormat('MM').format(DateTime.now());
  final String _selectedTahun = DateFormat('yyyy').format(DateTime.now());

  List<dynamic> _rekapSantri = [];
  List<dynamic> _izinKeluarList = [];
  List<dynamic> _laporans = [];

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
    _currentUser = Map<String, dynamic>.from(widget.user);
    _fetchRekapPresensi();
    _fetchIzinKeluar();
    _fetchPelanggaran();
  }

  Future<void> _fetchRekapPresensi() async {
    setState(() => _isLoadingRekap = true);
    try {
      final Map<String, dynamic> params = {
        'bulan': _selectedBulan,
        'tahun': _selectedTahun,
      };
      if (_selectedKategori != null && _selectedKategori!.isNotEmpty) {
        params['kategori'] = _selectedKategori;
      }

      final res = await _apiClient.dio.get('/presensi/rekap', queryParameters: params);
      if (mounted) {
        setState(() {
          _rekapSantri = res.data['data'] ?? [];
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingRekap = false);
    }
  }

  Future<void> _fetchIzinKeluar() async {
    setState(() => _isLoadingIzinKeluar = true);
    try {
      final res = await _apiClient.dio.get('/izin-keluar');
      if (mounted) {
        setState(() {
          _izinKeluarList = res.data['data']['data'] ?? [];
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingIzinKeluar = false);
    }
  }

  Future<void> _fetchPelanggaran() async {
    setState(() => _isLoadingPelanggaran = true);
    try {
      final res = await _apiClient.dio.get('/pelanggaran');
      if (mounted) {
        setState(() {
          _laporans = res.data['data']['data'] ?? [];
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingPelanggaran = false);
    }
  }

  String _formatWaktuClean(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '-';
    try {
      if (rawTime.contains('T')) {
        final dt = DateTime.parse(rawTime).toLocal();
        return '${DateFormat('HH:mm').format(dt)} WITA';
      }
      return rawTime.length >= 5 ? '${rawTime.substring(0, 5)} WITA' : rawTime;
    } catch (_) {
      return rawTime;
    }
  }

  /// Dialog Ubah Profil Pengurus (Username & Password)
  Future<void> _showEditPengurusProfileDialog() async {
    final usernameCtrl = TextEditingController(text: _user['username'] ?? '');
    final passwordCtrl = TextEditingController();
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
                    child: const Icon(Icons.admin_panel_settings_rounded, color: primaryCyan, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Profil Pengurus',
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
                        'Perbarui username login atau ubah kata sandi akun pengurus Anda.',
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
                            };
                            if (passwordCtrl.text.trim().isNotEmpty) {
                              payload['password'] = passwordCtrl.text.trim();
                            }

                            final res = await _apiClient.dio.post('/profile', data: payload);

                            setState(() {
                              _currentUser ??= Map<String, dynamic>.from(widget.user);
                              _currentUser!['username'] = usernameCtrl.text.trim();
                            });

                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.data['message'] ?? 'Profil Pengurus berhasil diperbarui!'),
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

  Future<void> _showDetailDatabaseMateriSantri(int santriId, String nama) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    const Color primaryCyan = Color(0xFF53D9DC);

    try {
      final res = await _apiClient.dio.get('/materi/rekap-santri/$santriId');
      final data = res.data['data'];
      final List<dynamic> logs = data['database_capaian_tervalidasi'] ?? [];
      final alquranPct = data['capaian_kurikulum_alquran']?['persentase_khatam'] ?? 0;
      final haditsPct = data['capaian_kurikulum_hadits']?['persentase_rata_rata_seluruh_kitab'] ?? 0;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: sheetBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2F3731) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: primaryCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Database Capaian Materi: $nama',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Capaian Al-Qur\'an: $alquranPct%  |  Hadits: $haditsPct%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryCyan,
                  ),
                ),
                const Divider(height: 20),
                Expanded(
                  child: logs.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada riwayat materi tervalidasi di database.',
                            style: TextStyle(color: onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          itemCount: logs.length,
                          itemBuilder: (context, i) {
                            final log = logs[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: primaryCyan.withValues(alpha: 0.2),
                                    child: const Icon(Icons.check, color: primaryCyan, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['judul_materi'] ?? '',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${log['detail_capaian']}\nValidator: ${log['validator']?['username'] ?? 'Guru'}',
                                          style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    (log['tanggal_validasi'] ?? '').toString().split('T').first,
                                    style: TextStyle(fontSize: 10, color: onSurfaceVariant),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.getErrorMessage(e))),
      );
    }
  }

  Future<void> _showValidasiPelanggaranDialog(Map<String, dynamic> item) async {
    String selectedKategori = item['kategori_pelanggaran'] == 'belum_divalidasi'
        ? 'ringan'
        : item['kategori_pelanggaran'];
    final tindakLanjutCtrl = TextEditingController(text: item['tindak_lanjut'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
        final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
        final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
        final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Validasi Laporan Anonim', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedKategori,
                      dropdownColor: cardColor,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        labelText: 'Tingkat Pelanggaran',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ringan', child: Text('RINGAN')),
                        DropdownMenuItem(value: 'sedang', child: Text('SEDANG')),
                        DropdownMenuItem(value: 'berat', child: Text('BERAT')),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedKategori = v ?? 'ringan'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tindakLanjutCtrl,
                      maxLines: 3,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        labelText: 'Tindak Lanjut / Pembinaan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: onSurfaceVariant)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B3B6),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (tindakLanjutCtrl.text.trim().isEmpty) return;
                    try {
                      await _apiClient.dio.patch(
                        '/pelanggaran/${item['id']}/validasi',
                        data: {
                          'kategori_pelanggaran': selectedKategori,
                          'tindak_lanjut': tindakLanjutCtrl.text.trim(),
                        },
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _fetchPelanggaran();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ApiClient.getErrorMessage(e))),
                      );
                    }
                  },
                  child: const Text('Simpan Validasi', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final Color navBg = isDark ? const Color(0xFF0E1510) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color borderColor = isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.06);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Area Profil Kiri Atas yang Tappable
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showEditPengurusProfileDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: primaryCyan, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Dashboard Pengurus',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_note_rounded, size: 16, color: onSurfaceVariant),
                                ],
                              ),
                              Text(
                                'Pengurus: ${_user['username']} (Akses Monitoring)',
                                style: const TextStyle(fontSize: 12, color: secondaryGold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Keluar',
                    onPressed: () async {
                      await _authService.logout();
                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
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
        children: [
          _buildRekapPresensiTab(),
          _buildIzinKeluarTab(),
          _buildPelanggaranTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryCyan : onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 64,
            indicatorColor: primaryContainer.withValues(alpha: 0.2),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined, color: onSurfaceVariant),
                selectedIcon: const Icon(Icons.analytics, color: primaryCyan),
                label: 'Rekap Presensi',
              ),
              NavigationDestination(
                icon: Icon(Icons.nightlight_outlined, color: onSurfaceVariant),
                selectedIcon: const Icon(Icons.nightlight_round, color: primaryCyan),
                label: 'Izin Keluar',
              ),
              NavigationDestination(
                icon: Icon(Icons.warning_amber_rounded, color: onSurfaceVariant),
                selectedIcon: const Icon(Icons.warning_rounded, color: primaryCyan),
                label: 'Pelanggaran',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 1: REKAP PRESENSI & MATERI (DARK THEME)
  // ============================================================================
  Widget _buildRekapPresensiTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.08);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color secondaryGold = Color(0xFFEDBF70);

    return Column(
      children: [
        Container(
          color: cardColor,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
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
                          value: _selectedKategori,
                          dropdownColor: cardColor,
                          hint: Text('Semua Kategori (6 Sesi)', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Kategori (6 Sesi)', style: TextStyle(fontSize: 12, color: onSurface)),
                            ),
                            ..._kategoriLabels.entries.map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value, style: TextStyle(fontSize: 12, color: onSurface)),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedKategori = v);
                            _fetchRekapPresensi();
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
                            _fetchRekapPresensi();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [Color(0xFF12B3B6), Color(0xFF00696B)]),
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
                    kategori: _selectedKategori,
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Ekspor Rekap Presensi & Jam Malam (.CSV)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRekapPresensi,
            child: _isLoadingRekap
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: _rekapSantri.length,
                    itemBuilder: (context, idx) {
                      final s = _rekapSantri[idx];
                      final String nama = s['santri_profile']?['nama_lengkap'] ?? s['username'] ?? 'Santri';
                      final String kamar = s['santri_profile']?['kamar'] ?? '-';
                      final int izinKeluarCount = s['izin_keluar_count'] ?? 0;
                      final int lewatJamMalamCount = s['lewat_jam_malam_count'] ?? 0;
                      final int materiValidCount = s['materi_tervalidasi_count'] ?? 0;

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
                            Text(nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface)),
                            Text('Kamar: $kamar', style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _miniBadge('Hadir: ${s['hadir_count'] ?? 0}', primaryCyan),
                                _miniBadge('Izin: ${s['izin_count'] ?? 0}', const Color(0xFF7AD5D7)),
                                _miniBadge('Sakit: ${s['sakit_count'] ?? 0}', secondaryGold),
                                _miniBadge('Alpha: ${s['alpha_count'] ?? 0}', const Color(0xFFFFB4AB)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Izin Keluar: $izinKeluarCount x  |  Lewat 23:00 WITA: $lewatJamMalamCount x',
                              style: TextStyle(
                                fontSize: 11,
                                color: lewatJamMalamCount > 0 ? const Color(0xFFFFB4AB) : onSurfaceVariant,
                                fontWeight: lewatJamMalamCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Materi Tuntas (Database): $materiValidCount Materi',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryGold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: BorderSide(color: outlineColor.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showDetailDatabaseMateriSantri(s['id'], nama),
                                icon: const Icon(Icons.auto_stories_rounded, size: 16),
                                label: const Text('Buka Database Capaian Santri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: MONITORING IZIN KELUAR & JAM MALAM (DARK THEME)
  // ============================================================================
  Widget _buildIzinKeluarTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.08);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color secondaryGold = Color(0xFFEDBF70);
    const Color dangerRed = Color(0xFFFFB4AB);

    final int totalLewatJamMalam = _izinKeluarList.where((e) => e['is_lewat_jam_malam'] == true).length;
    final int totalPending = _izinKeluarList.where((e) => (e['status_approval'] ?? '').toString().toLowerCase() == 'pending').length;

    return RefreshIndicator(
      onRefresh: _fetchIzinKeluar,
      child: _isLoadingIzinKeluar
          ? const Center(child: CircularProgressIndicator())
          : _izinKeluarList.isEmpty
              ? Center(child: Text('Belum ada data izin keluar / jam malam.', style: TextStyle(color: onSurfaceVariant)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Izin',
                            '${_izinKeluarList.length}',
                            Icons.assignment_outlined,
                            primaryCyan,
                            cardColor,
                            outlineColor,
                            onSurface,
                            onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            'Lewat 23:00',
                            '$totalLewatJamMalam',
                            Icons.alarm_off_rounded,
                            totalLewatJamMalam > 0 ? dangerRed : onSurfaceVariant,
                            cardColor,
                            outlineColor,
                            onSurface,
                            onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            'Pending',
                            '$totalPending',
                            Icons.hourglass_top_rounded,
                            secondaryGold,
                            cardColor,
                            outlineColor,
                            onSurface,
                            onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(_izinKeluarList.length, (idx) {
                      final iz = _izinKeluarList[idx];
                      final santri = iz['santri'] ?? {};
                      final String nama = santri['santri_profile']?['nama_lengkap'] ?? santri['username'] ?? 'Santri';
                      final String kamar = santri['santri_profile']?['kamar'] ?? '-';
                      final bool lewat23 = iz['is_lewat_jam_malam'] == true;
                      final String status = (iz['status_approval'] ?? 'pending').toString().toUpperCase();
                      final String? buktiPath = iz['bukti_foto_webp'];
                      final String tanggal = (iz['tanggal'] ?? '').toString().split('T').first;
                      final String keperluan = iz['keperluan'] ?? '-';
                      final String? lokasiGps = iz['lokasi_gps'] ?? iz['alamat_gps'];

                      final Color statusColor = status == 'APPROVED'
                          ? primaryCyan
                          : status == 'REJECTED'
                              ? dangerRed
                              : secondaryGold;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: lewat23 ? dangerRed.withValues(alpha: 0.6) : outlineColor,
                            width: lewat23 ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            if (lewat23)
                              BoxShadow(
                                color: dangerRed.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: lewat23 ? dangerRed.withValues(alpha: 0.15) : primaryCyan.withValues(alpha: 0.15),
                                    child: Icon(
                                      lewat23 ? Icons.warning_amber_rounded : Icons.person_pin_circle_rounded,
                                      size: 20,
                                      color: lewat23 ? dangerRed : primaryCyan,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: secondaryGold.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Kamar: $kamar',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: secondaryGold),
                                              ),
                                            ),
                                            Text(
                                              tanggal,
                                              style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (lewat23) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          margin: const EdgeInsets.only(bottom: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF93000A),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'LEWAT 23:00',
                                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                          ),
                                        ),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildTimeInfo(
                                            'Jam Keluar',
                                            _formatWaktuClean(iz['waktu_keluar']),
                                            Icons.call_made_rounded,
                                            onSurface,
                                            onSurfaceVariant,
                                          ),
                                        ),
                                        Container(width: 1, height: 26, color: outlineColor),
                                        Expanded(
                                          child: _buildTimeInfo(
                                            'Estimasi',
                                            _formatWaktuClean(iz['estimasi_kembali']),
                                            Icons.access_time_rounded,
                                            onSurface,
                                            onSurfaceVariant,
                                          ),
                                        ),
                                        Container(width: 1, height: 26, color: outlineColor),
                                        Expanded(
                                          child: _buildTimeInfo(
                                            'Kembali',
                                            _formatWaktuClean(iz['waktu_kembali_aktual']),
                                            Icons.task_alt_rounded,
                                            iz['waktu_kembali_aktual'] != null ? primaryCyan : onSurfaceVariant,
                                            onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes_rounded, size: 15, color: secondaryGold),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(fontSize: 12, color: onSurface),
                                            children: [
                                              TextSpan(text: 'Keperluan: ', style: TextStyle(color: onSurfaceVariant, fontWeight: FontWeight.w500)),
                                              TextSpan(text: keperluan, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (lokasiGps != null && lokasiGps.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 15, color: onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            lokasiGps,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (buktiPath != null && buktiPath.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          side: BorderSide(color: primaryCyan.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          backgroundColor: primaryCyan.withValues(alpha: 0.05),
                                        ),
                                        onPressed: () => ExcelExporterHelper.showFullScreenImage(
                                          context,
                                          '${ApiClient.storageBaseUrl}$buktiPath',
                                          title: 'Foto Bukti Izin: $nama',
                                        ),
                                        icon: const Icon(Icons.center_focus_strong_rounded, size: 16, color: primaryCyan),
                                        label: const Text(
                                          'Lihat Foto Bukti Presensi / Kembalian',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryCyan),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }

  // ============================================================================
  // TAB 3: PELANGGARAN & PENGADUAN ANONIM (DARK THEME)
  // ============================================================================
  Widget _buildPelanggaranTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);
    const Color primaryCyan = Color(0xFF53D9DC);

    return RefreshIndicator(
      onRefresh: _fetchPelanggaran,
      child: _isLoadingPelanggaran
          ? const Center(child: CircularProgressIndicator())
          : _laporans.isEmpty
              ? Center(child: Text('Belum ada laporan pelanggaran anonim.', style: TextStyle(color: onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _laporans.length,
                  itemBuilder: (context, idx) {
                    final lap = _laporans[idx];
                    final String kategori = lap['kategori_pelanggaran'] ?? 'belum_divalidasi';
                    final String namaTerlapor = lap['terlapor']?['santri_profile']?['nama_lengkap'] ??
                        lap['terlapor']?['username'] ??
                        'Terlapor Disebut di Deskripsi';
                    final String? fotoPath = lap['bukti_foto_webp'];

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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_rounded, size: 16, color: primaryCyan),
                                  SizedBox(width: 6),
                                  Text(
                                    'Pelapor: 100% ANONIM',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryCyan),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(kategori.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryCyan)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Terlapor: $namaTerlapor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
                          const SizedBox(height: 4),
                          Text(lap['deskripsi'] ?? '', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          if (fotoPath != null && fotoPath.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => ExcelExporterHelper.showFullScreenImage(
                                context,
                                '${ApiClient.storageBaseUrl}$fotoPath',
                                title: 'Bukti Pelanggaran: $namaTerlapor',
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${ApiClient.storageBaseUrl}$fotoPath',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                          if (lap['tindak_lanjut'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tindak Lanjut: ${lap['tindak_lanjut']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFEDBF70), fontWeight: FontWeight.bold),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF12B3B6),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showValidasiPelanggaranDialog(lap),
                              child: const Text('Validasi & Tindak Lanjut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _miniBadge(String text, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String count,
    IconData icon,
    Color accentColor,
    Color bg,
    Color border,
    Color textColor,
    Color labelColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: labelColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(
    String label,
    String value,
    IconData icon,
    Color valueColor,
    Color labelColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10, color: labelColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 9, color: labelColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}