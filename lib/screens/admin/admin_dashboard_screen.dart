import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/excel_exporter_helper.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

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

    final List<Widget> pages = [
      const _AdminCrudUsersTab(),
      const _AdminRekapPresensiMateriTab(),
      const _AdminIzinJamMalamTab(),
      const _AdminPengaduanPelanggaranTab(),
    ];

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
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user, color: primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Administrator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          'Super Admin: ${widget.user['username']} (Akses Penuh)',
                          style: TextStyle(fontSize: 12, color: secondaryGold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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
          color: navBg,
          border: Border(top: BorderSide(color: borderColor)),
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
              icon: Icon(Icons.manage_accounts_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.manage_accounts, color: primaryCyan),
              label: 'Kelola User',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.analytics, color: primaryCyan),
              label: 'Rekap & Materi',
            ),
            NavigationDestination(
              icon: Icon(Icons.nightlight_outlined, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.nightlight_round, color: primaryCyan),
              label: 'Izin Keluar',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_rounded, color: onSurfaceVariant),
              selectedIcon: const Icon(Icons.warning_rounded, color: primaryCyan),
              label: 'Pengaduan',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 1: KELOLA USER
// ============================================================================
class _AdminCrudUsersTab extends StatefulWidget {
  const _AdminCrudUsersTab();

  @override
  State<_AdminCrudUsersTab> createState() => _AdminCrudUsersTabState();
}

class _AdminCrudUsersTabState extends State<_AdminCrudUsersTab> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String _selectedRoleFilter = 'santri';
  List<dynamic> _usersList = [];
  List<dynamic> _filteredUsersList = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        '/admin/users',
        queryParameters: {'role': _selectedRoleFilter},
      );
      if (mounted) {
        setState(() {
          _usersList = res.data['data'] ?? [];
          _filterUsers(_searchCtrl.text);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.getErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredUsersList = _usersList);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredUsersList = _usersList.where((u) {
          final profile = u['santri_profile'] ?? {};
          final nama = (profile['nama_lengkap'] ?? '').toString().toLowerCase();
          final username = (u['username'] ?? '').toString().toLowerCase();
          final kamar = (profile['kamar'] ?? '').toString().toLowerCase();
          return nama.contains(q) || username.contains(q) || kamar.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _showEditKredensialDialog(Map<String, dynamic> user) async {
    final usernameCtrl = TextEditingController(text: user['username'] ?? '');
    final passwordCtrl = TextEditingController();
    String statusKeaktifan = user['status_keaktifan'] ?? 'aktif';
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
            final profile = user['santri_profile'] ?? {};
            final nama = profile['nama_lengkap'] ?? user['username'] ?? 'User';

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Kelola Akun: $nama', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perbarui username login, reset kata sandi, atau atur status keaktifan.',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        labelText: 'Password Baru',
                        hintText: 'Kosongkan jika tidak ingin mereset',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['aktif', 'magang', 'alumni', 'boyong'].contains(statusKeaktifan)
                          ? statusKeaktifan
                          : 'aktif',
                      dropdownColor: cardColor,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        labelText: 'Status Keaktifan Akun',
                        prefixIcon: const Icon(Icons.verified_user_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                        DropdownMenuItem(value: 'magang', child: Text('Magang / PKL')),
                        DropdownMenuItem(value: 'alumni', child: Text('Alumni')),
                        DropdownMenuItem(value: 'boyong', child: Text('Boyong / Keluar')),
                      ],
                      onChanged: (v) => setStateDialog(() => statusKeaktifan = v ?? 'aktif'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: onSurfaceVariant)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() => isSaving = true);
                          try {
                            final payload = <String, dynamic>{
                              'username': usernameCtrl.text.trim(),
                              'role': user['role'],
                              'status_keaktifan': statusKeaktifan,
                            };
                            if (passwordCtrl.text.trim().isNotEmpty) {
                              payload['password'] = passwordCtrl.text.trim();
                            }

                            await _apiClient.dio.put('/admin/users/${user['id']}', data: payload);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Akun & password berhasil diperbarui!')),
                            );
                            _fetchUsers();
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ApiClient.getErrorMessage(e))),
                            );
                          }
                        },
                  child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDetailProfilSantriSheet(Map<String, dynamic> user) {
    final p = user['santri_profile'] ?? {};
    final String nama = p['nama_lengkap'] ?? user['username'] ?? 'Santri';
    final String? foto = p['foto_profil_webp'];

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    const Color primaryCyan = Color(0xFF53D9DC);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF12B3B6),
                  backgroundImage: foto != null && foto.isNotEmpty
                      ? NetworkImage('${ApiClient.storageBaseUrl}$foto')
                      : null,
                  child: foto == null || foto.isEmpty
                      ? Text(
                          nama.isNotEmpty ? nama[0].toUpperCase() : 'S',
                          style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        '@${user['username']} • Panggilan: ${p['nama_panggilan'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Status: ${(user['status_keaktifan'] ?? 'aktif').toString().toUpperCase()}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryCyan),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _buildSectionHeader('1. Data Personal & Asrama', Icons.home_work_rounded, primaryCyan),
            _buildInfoRow('Jenis Kelamin', p['jenis_kelamin'] == 'L' ? 'Laki-laki (L)' : (p['jenis_kelamin'] == 'P' ? 'Perempuan (P)' : '-'), onSurface, onSurfaceVariant),
            _buildInfoRow('Kamar Asrama', p['kamar'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('WhatsApp Santri', p['no_wa_santri'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Nama Bapak', p['nama_bapak'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Nama Ibu', p['nama_ibu'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('WhatsApp Orang Tua', p['no_wa_ortu'] ?? '-', onSurface, onSurfaceVariant),
            const SizedBox(height: 16),
            _buildSectionHeader('2. Data Kepesantrenan & Sambung', Icons.mosque_rounded, primaryCyan),
            _buildInfoRow('Tingkat Kurikulum', (p['tingkatan_kelas'] ?? 'Makna Lambat').toString().replaceAll('_', ' ').toUpperCase(), onSurface, onSurfaceVariant),
            _buildInfoRow('Asal Provinsi', p['asal_provinsi'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Asal Kota / Kab', p['asal_kota_kab'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Asal Tempat Sambung', p['asal_tempat_sambung'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Status Mubaligh', p['status_mubaligh'] ?? '-', onSurface, onSurfaceVariant),
            const SizedBox(height: 16),
            _buildSectionHeader('3. Data Akademik Perguruan Tinggi', Icons.school_rounded, primaryCyan),
            _buildInfoRow('Kampus / Universitas', p['kampus'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Fakultas', p['fakultas'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Jurusan', p['jurusan'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Program Studi (Prodi)', p['prodi'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Angkatan Kuliah', p['angkatan_kuliah'] ?? '-', onSurface, onSurfaceVariant),
            _buildInfoRow('Beasiswa', p['beasiswa'] ?? '-', onSurface, onSurfaceVariant),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12B3B6),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditKredensialDialog(user);
              },
              icon: const Icon(Icons.vpn_key_rounded, size: 18),
              label: const Text('Ubah Username / Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
          ),
          Text(': ', style: TextStyle(fontSize: 12, color: labelColor)),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTambahUserDialog() async {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    final kamarCtrl = TextEditingController();
    String role = _selectedRoleFilter;
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
          builder: (context, setStateDialog) => AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Tambah ${role.toUpperCase()} Baru', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: namaCtrl,
                    style: TextStyle(color: onSurface, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: usernameCtrl,
                    style: TextStyle(color: onSurface, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      labelText: 'Username (Login)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordCtrl,
                    style: TextStyle(color: onSurface, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (role == 'santri') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: kamarCtrl,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        labelText: 'Kamar Asrama',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: Text('Batal', style: TextStyle(color: onSurfaceVariant)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
                        setStateDialog(() => isSaving = true);
                        try {
                          await _apiClient.dio.post('/admin/users', data: {
                            'username': usernameCtrl.text.trim(),
                            'password': passwordCtrl.text.trim(),
                            'role': role,
                            'nama_lengkap': namaCtrl.text.trim(),
                            'kamar': kamarCtrl.text.trim(),
                          });
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _fetchUsers();
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
                        }
                      },
                child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(int id, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: Text('Yakin ingin menghapus akun @$username secara permanen?'),
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
      await _apiClient.dio.delete('/admin/users/$id');
      _fetchUsers();
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
    const Color secondaryGold = Color(0xFFEDBF70);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_user',
        backgroundColor: const Color(0xFF12B3B6),
        foregroundColor: Colors.black,
        onPressed: _showTambahUserDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Tambah ${_selectedRoleFilter.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Segmented Role Filter
          Container(
            color: cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'santri', label: Text('Santri')),
                ButtonSegment(value: 'guru', label: Text('Guru')),
                ButtonSegment(value: 'pengurus', label: Text('Pengurus')),
              ],
              selected: {_selectedRoleFilter},
              onSelectionChanged: (v) {
                setState(() => _selectedRoleFilter = v.first);
                _fetchUsers();
              },
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterUsers,
              style: TextStyle(color: onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari santri, username, kamar...',
                hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsersList.isEmpty
                      ? Center(child: Text('Belum ada data pada kategori ini.', style: TextStyle(color: onSurfaceVariant)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _filteredUsersList.length,
                          itemBuilder: (context, idx) {
                            final u = _filteredUsersList[idx];
                            final profile = u['santri_profile'] ?? {};
                            final String nama = profile['nama_lengkap'] ?? u['username'];
                            final String kamar = profile['kamar'] ?? '-';
                            final String hp = profile['no_wa_santri'] ?? profile['no_hp'] ?? '-';
                            final String status = u['status_keaktifan'] ?? 'aktif';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: primaryCyan.withValues(alpha: 0.2),
                                        child: Text(
                                          nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                                          style: const TextStyle(color: primaryCyan, fontWeight: FontWeight.bold),
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
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '@${u['username']} • $kamar',
                                              style: TextStyle(fontSize: 11, color: secondaryGold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'aktif'
                                              ? primaryCyan.withValues(alpha: 0.15)
                                              : Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'aktif' ? primaryCyan : Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.call, size: 14, color: secondaryGold),
                                            const SizedBox(width: 6),
                                            Text(hp, style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Icon(Icons.verified, size: 12, color: primaryCyan),
                                            SizedBox(width: 4),
                                            Text('Induk Sah', style: TextStyle(fontSize: 10, color: primaryCyan, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            side: BorderSide(color: outlineColor.withValues(alpha: 0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _showEditKredensialDialog(u),
                                          icon: const Icon(Icons.key, size: 14, color: secondaryGold),
                                          label: const Text('Reset Sandi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        tooltip: 'Detail Profil',
                                        icon: const Icon(Icons.badge_outlined, size: 18, color: primaryCyan),
                                        onPressed: () => _showDetailProfilSantriSheet(u),
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus User',
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        onPressed: () => _deleteUser(u['id'], u['username']),
                                      ),
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
}

// ============================================================================
// TAB 2: REKAP PRESENSI & DATABASE MATERI TUNTAS
// ============================================================================
class _AdminRekapPresensiMateriTab extends StatefulWidget {
  const _AdminRekapPresensiMateriTab();

  @override
  State<_AdminRekapPresensiMateriTab> createState() => _AdminRekapPresensiMateriTabState();
}

class _AdminRekapPresensiMateriTabState extends State<_AdminRekapPresensiMateriTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _filterKategori;
  String _selectedBulan = DateFormat('MM').format(DateTime.now());
  final String _selectedTahun = DateFormat('yyyy').format(DateTime.now());
  List<dynamic> _rekapList = [];

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
    _fetchRekap();
  }

  Future<void> _fetchRekap() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        '/presensi/rekap',
        queryParameters: {
          'bulan': _selectedBulan,
          'tahun': _selectedTahun,
          if (_filterKategori != null) 'kategori': _filterKategori,
        },
      );
      if (mounted) {
        setState(() {
          _rekapList = res.data['data'] ?? [];
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAsisten(int userId, bool currentStatus) async {
    final bool newStatus = !currentStatus;
    setState(() {
      final idx = _rekapList.indexWhere((e) => e['id'] == userId);
      if (idx != -1) {
        _rekapList[idx]['is_asisten_guru'] = newStatus;
      }
    });

    try {
      await _apiClient.dio.patch('/users/$userId/toggle-asisten', data: {'is_asisten_guru': newStatus});
    } catch (_) {
      _fetchRekap();
    }
  }

  Future<void> _showDetailDatabaseSantri(int santriId, String namaSantri) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    const Color primaryCyan = Color(0xFF53D9DC);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, scrollController) => FutureBuilder(
          future: _apiClient.dio.get('/materi/rekap-santri/$santriId'),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(ApiClient.getErrorMessage(snapshot.error)));
            }

            final resData = snapshot.data?.data['data'] ?? {};
            final List<dynamic> logs = resData['database_capaian_tervalidasi'] ?? resData['database_logs'] ?? [];
            final alquranPct = resData['capaian_kurikulum_alquran']?['persentase_khatam'] ?? 0;
            final haditsPct = resData['capaian_kurikulum_hadits']?['persentase_rata_rata_seluruh_kitab'] ?? 0;

            return Padding(
              padding: const EdgeInsets.all(16.0),
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
                          'Database Capaian: $namaSantri',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Al-Qur\'an: $alquranPct% | Hadits: $haditsPct%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryCyan),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada materi yang tervalidasi di database.',
                              style: TextStyle(color: onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: logs.length,
                            itemBuilder: (context, i) {
                              final item = logs[i];
                              final tingkatan = (item['tingkatan_kelas'] ?? '').toString().replaceAll('_', ' ').toUpperCase();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['judul_materi'] ?? '',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
                                          ),
                                        ),
                                        if (tingkatan.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primaryCyan.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tingkatan,
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryCyan),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['detail_capaian']}\nValidator: ${item['validator']?['username'] ?? 'Guru'}${item['catatan'] != null && item['catatan'].toString().isNotEmpty ? '\nCatatan: ${item['catatan']}' : ''}',
                                      style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

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
                          value: _filterKategori,
                          dropdownColor: cardColor,
                          hint: Text('Semua Kategori (6 Sesi)', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          items: [
                            DropdownMenuItem<String?>(value: null, child: Text('Semua Kategori (6 Sesi)', style: TextStyle(fontSize: 12, color: onSurface))),
                            ..._kategoriLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(fontSize: 12, color: onSurface)))),
                          ],
                          onChanged: (v) {
                            setState(() => _filterKategori = v);
                            _fetchRekap();
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
                            return DropdownMenuItem(value: m, child: Text('Bulan $m', style: TextStyle(fontSize: 12, color: onSurface)));
                          }),
                          onChanged: (v) {
                            setState(() => _selectedBulan = v ?? '01');
                            _fetchRekap();
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
                    kategori: _filterKategori,
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                  label: const Text('Ekspor Rekap (.CSV / Excel)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRekap,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: _rekapList.length,
                    itemBuilder: (context, idx) {
                      final s = _rekapList[idx];
                      final String nama = s['nama_lengkap'] ?? s['username'] ?? 'Santri';
                      final String kamar = s['kamar'] ?? '-';
                      final bool isAsisten = s['is_asisten_guru'] == true;
                      final int totalHadir = s['total_hadir'] ?? 0;
                      final int totalIzin = s['total_izin'] ?? 0;
                      final int totalSakit = s['total_sakit'] ?? 0;
                      final int totalAlpha = s['total_alpha'] ?? 0;
                      final int totalKeluar = s['total_izin_keluar'] ?? 0;
                      final int totalLewat23 = s['total_lewat_jam_malam'] ?? 0;
                      final int totalTuntas = s['total_materi_tuntas'] ?? 0;

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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface)),
                                      Text('Kamar: $kamar', style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Asisten', style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                                    const SizedBox(width: 4),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: isAsisten,
                                        activeColor: primaryCyan,
                                        onChanged: (val) => _toggleAsisten(s['id'], isAsisten),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _miniBadge('Hadir: $totalHadir', primaryCyan),
                                _miniBadge('Izin: $totalIzin', const Color(0xFF7AD5D7)),
                                _miniBadge('Sakit: $totalSakit', secondaryGold),
                                _miniBadge('Alpha: $totalAlpha', const Color(0xFFFFB4AB)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Izin Keluar: $totalKeluar x  |  Lewat 23:00 WITA: $totalLewat23 x',
                              style: TextStyle(
                                fontSize: 11,
                                color: totalLewat23 > 0 ? const Color(0xFFFFB4AB) : onSurfaceVariant,
                                fontWeight: totalLewat23 > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Materi Tuntas (Database): $totalTuntas Materi',
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
                                onPressed: () => _showDetailDatabaseSantri(s['id'], nama),
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

  Widget _miniBadge(String text, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
    );
  }
}

// ============================================================================
// TAB 3: MONITORING LENGKAP IZIN KELUAR & JAM MALAM (NO OVERFLOW FIX)
// ============================================================================
class _AdminIzinJamMalamTab extends StatefulWidget {
  const _AdminIzinJamMalamTab();

  @override
  State<_AdminIzinJamMalamTab> createState() => _AdminIzinJamMalamTabState();
}

class _AdminIzinJamMalamTabState extends State<_AdminIzinJamMalamTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _izinList = [];

  @override
  void initState() {
    super.initState();
    _fetchIzin();
  }

  Future<void> _fetchIzin() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/izin-keluar');
      if (mounted) {
        setState(() {
          _izinList = res.data['data']['data'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Format Jam Singkat (HH:mm WITA) agar tidak memakan ruang grid jam
  String _formatWaktuClean(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '-';
    try {
      if (rawTime.contains('T')) {
        final dt = DateTime.parse(rawTime).toLocal();
        return DateFormat('HH:mm').format(dt) + ' WITA';
      }
      return rawTime.length >= 5 ? rawTime.substring(0, 5) + ' WITA' : rawTime;
    } catch (_) {
      return rawTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF242C26) : Colors.black.withValues(alpha: 0.08);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color secondaryGold = Color(0xFFEDBF70);
    const Color dangerRed = Color(0xFFFFB4AB);

    final int totalLewatJamMalam = _izinList.where((e) => e['is_lewat_jam_malam'] == true).length;
    final int totalPending = _izinList.where((e) => (e['status_approval'] ?? '').toString().toLowerCase() == 'pending').length;

    return RefreshIndicator(
      onRefresh: _fetchIzin,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _izinList.isEmpty
              ? Center(child: Text('Belum ada data izin keluar / jam malam.', style: TextStyle(color: onSurfaceVariant)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Ringkasan Statistik Quick View
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Izin',
                            '${_izinList.length}',
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

                    // Daftar Card Izin Keluar
                    ...List.generate(_izinList.length, (idx) {
                      final iz = _izinList[idx];
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
                            // Header Card (Responsif & Anti-Overflow)
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

                            // Body Data Jam & Keperluan
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Grid Timings 3 Kolom
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

                                  // Detail Keperluan
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

                                  // Informasi Lokasi GPS jika ada
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

                                  // Action Bukti Foto
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

  // Widget Helper Sub-Card Statistik
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

  // Widget Helper Informasi Jam
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

// ============================================================================
// TAB 4: PENGADUAN & PELANGGARAN ANONIM
// ============================================================================
class _AdminPengaduanPelanggaranTab extends StatefulWidget {
  const _AdminPengaduanPelanggaranTab();

  @override
  State<_AdminPengaduanPelanggaranTab> createState() => _AdminPengaduanPelanggaranTabState();
}

class _AdminPengaduanPelanggaranTabState extends State<_AdminPengaduanPelanggaranTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _laporans = [];

  @override
  void initState() {
    super.initState();
    _fetchPelanggaran();
  }

  Future<void> _fetchPelanggaran() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/pelanggaran');
      if (mounted) {
        setState(() {
          _laporans = res.data['data']['data'] ?? [];
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showValidasiDialog(Map<String, dynamic> item) async {
    String selectedKategori = item['kategori_pelanggaran'] == 'belum_divalidasi' ? 'ringan' : item['kategori_pelanggaran'];
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.getErrorMessage(e))));
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);
    const Color primaryCyan = Color(0xFF53D9DC);

    return RefreshIndicator(
      onRefresh: _fetchPelanggaran,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _laporans.isEmpty
              ? Center(child: Text('Belum ada laporan pelanggaran anonim.', style: TextStyle(color: onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _laporans.length,
                  itemBuilder: (context, idx) {
                    final lap = _laporans[idx];
                    final String kategori = lap['kategori_pelanggaran'] ?? 'belum_divalidasi';
                    final String namaTerlapor = lap['terlapor']?['santri_profile']?['nama_lengkap'] ?? lap['terlapor']?['username'] ?? 'Terlapor';
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
                              onPressed: () => _showValidasiDialog(lap),
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
}