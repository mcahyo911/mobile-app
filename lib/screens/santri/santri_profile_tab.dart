import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/image_compressor_helper.dart';

class SantriProfileTab extends StatefulWidget {
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;

  const SantriProfileTab({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<SantriProfileTab> createState() => _SantriProfileTabState();
}

class _SantriProfileTabState extends State<SantriProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  bool _isSaving = false;
  File? _newFotoProfilWebp;
  String? _existingFotoPath;

  // Controller Kredensial Akun
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _currentPasswordCtrl;
  late final TextEditingController _newPasswordCtrl;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  // Controller Biodata Santri
  late final TextEditingController _namaLengkapCtrl;
  late final TextEditingController _namaPanggilanCtrl;
  late final TextEditingController _kamarCtrl;
  late final TextEditingController _noWaSantriCtrl;
  late final TextEditingController _namaBapakCtrl;
  late final TextEditingController _namaIbuCtrl;
  late final TextEditingController _noWaOrtuCtrl;
  late final TextEditingController _asalProvinsiCtrl;
  late final TextEditingController _asalKotaKabCtrl;
  late final TextEditingController _asalDaerahCtrl;
  late final TextEditingController _asalDesaCtrl;
  late final TextEditingController _asalKelompokCtrl;
  late final TextEditingController _kampusCtrl;
  late final TextEditingController _fakultasCtrl;
  late final TextEditingController _jurusanCtrl;
  late final TextEditingController _prodiCtrl;
  late final TextEditingController _angkatanCtrl;
  late final TextEditingController _beasiswaCtrl;

  String _jenisKelamin = 'L';
  String _statusMubaligh = 'belum';

  // Theme Colors Dark Surface
  static const Color colorSurface = Color(0xFF0E1510);
  static const Color colorSurfaceContainerLow = Color(0xFF161D18);
  static const Color colorSurfaceContainerLowest = Color(0xFF09100B);
  static const Color colorSurfaceContainerHighest = Color(0xFF2F3731);
  static const Color colorPrimary = Color(0xFF53D9DC);
  static const Color colorPrimaryContainer = Color(0xFF12B3B6);
  static const Color colorOnPrimary = Color(0xFF003738);
  static const Color colorSecondary = Color(0xFFEDBF70);
  static const Color colorSecondaryContainer = Color(0xFF6A4A01);
  static const Color colorOnSurface = Color(0xFFDDE5DC);
  static const Color colorOnSurfaceVariant = Color(0xFFBBC9C9);
  static const Color colorInversePrimary = Color(0xFF00696B);

  @override
  void initState() {
    super.initState();
    final p = widget.user['santri_profile'] as Map<String, dynamic>? ?? {};

    _existingFotoPath = p['foto_profil_webp'];
    _jenisKelamin = p['jenis_kelamin'] ?? 'L';
    _statusMubaligh = p['status_mubaligh'] ?? 'belum';

    // Kredensial Akun
    _usernameCtrl = TextEditingController(text: widget.user['username'] ?? '');
    _currentPasswordCtrl = TextEditingController();
    _newPasswordCtrl = TextEditingController();

    // Biodata
    _namaLengkapCtrl = TextEditingController(text: p['nama_lengkap'] ?? '');
    _namaPanggilanCtrl = TextEditingController(text: p['nama_panggilan'] ?? '');
    _kamarCtrl = TextEditingController(text: p['kamar'] ?? '');
    _noWaSantriCtrl = TextEditingController(text: p['no_wa_santri'] ?? '');
    _namaBapakCtrl = TextEditingController(text: p['nama_bapak'] ?? '');
    _namaIbuCtrl = TextEditingController(text: p['nama_ibu'] ?? '');
    _noWaOrtuCtrl = TextEditingController(text: p['no_wa_ortu'] ?? '');
    _asalProvinsiCtrl = TextEditingController(text: p['asal_provinsi'] ?? '');
    _asalKotaKabCtrl = TextEditingController(text: p['asal_kota_kab'] ?? '');

    final String rawSambung = p['asal_tempat_sambung'] ?? '';
    String daerah = '', desa = '', kelompok = '';
    if (rawSambung.contains('|')) {
      final parts = rawSambung.split('|').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) daerah = parts[0].replaceFirst('Daerah: ', '');
      if (parts.length > 1) desa = parts[1].replaceFirst('Desa: ', '');
      if (parts.length > 2) kelompok = parts[2].replaceFirst('Kelompok: ', '');
    } else {
      desa = rawSambung;
    }

    _asalDaerahCtrl = TextEditingController(text: daerah);
    _asalDesaCtrl = TextEditingController(text: desa);
    _asalKelompokCtrl = TextEditingController(text: kelompok);

    _kampusCtrl = TextEditingController(text: p['kampus'] ?? '');
    _fakultasCtrl = TextEditingController(text: p['fakultas'] ?? '');
    _jurusanCtrl = TextEditingController(text: p['jurusan'] ?? '');
    _prodiCtrl = TextEditingController(text: p['prodi'] ?? '');
    _angkatanCtrl = TextEditingController(
      text: p['angkatan_kuliah']?.toString() ?? '',
    );
    _beasiswaCtrl = TextEditingController(text: p['beasiswa'] ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _namaLengkapCtrl.dispose();
    _namaPanggilanCtrl.dispose();
    _kamarCtrl.dispose();
    _noWaSantriCtrl.dispose();
    _namaBapakCtrl.dispose();
    _namaIbuCtrl.dispose();
    _noWaOrtuCtrl.dispose();
    _asalProvinsiCtrl.dispose();
    _asalKotaKabCtrl.dispose();
    _asalDaerahCtrl.dispose();
    _asalDesaCtrl.dispose();
    _asalKelompokCtrl.dispose();
    _kampusCtrl.dispose();
    _fakultasCtrl.dispose();
    _jurusanCtrl.dispose();
    _prodiCtrl.dispose();
    _angkatanCtrl.dispose();
    _beasiswaCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final String combinedTempatSambung =
          'Daerah: ${_asalDaerahCtrl.text.trim()} | Desa: ${_asalDesaCtrl.text.trim()} | Kelompok: ${_asalKelompokCtrl.text.trim()}';

      final Map<String, dynamic> payload = {
        'username': _usernameCtrl.text.trim(),
        'nama_lengkap': _namaLengkapCtrl.text.trim(),
        'nama_panggilan': _namaPanggilanCtrl.text.trim(),
        'jenis_kelamin': _jenisKelamin,
        'kamar': _kamarCtrl.text.trim(),
        'no_wa_santri': _noWaSantriCtrl.text.trim(),
        'nama_bapak': _namaBapakCtrl.text.trim(),
        'nama_ibu': _namaIbuCtrl.text.trim(),
        'no_wa_ortu': _noWaOrtuCtrl.text.trim(),
        'asal_provinsi': _asalProvinsiCtrl.text.trim(),
        'asal_kota_kab': _asalKotaKabCtrl.text.trim(),
        'asal_tempat_sambung': combinedTempatSambung,
        'status_mubaligh': _statusMubaligh,
        'kampus': _kampusCtrl.text.trim(),
        'fakultas': _fakultasCtrl.text.trim(),
        'jurusan': _jurusanCtrl.text.trim(),
        'prodi': _prodiCtrl.text.trim(),
        'beasiswa': _beasiswaCtrl.text.trim(),
      };

      // Sertakan pergantian kata sandi jika diisi
      if (_newPasswordCtrl.text.trim().isNotEmpty) {
        payload['current_password'] = _currentPasswordCtrl.text;
        payload['new_password'] = _newPasswordCtrl.text;
      }

      if (_angkatanCtrl.text.trim().length == 4) {
        payload['angkatan_kuliah'] = int.tryParse(_angkatanCtrl.text.trim());
      }

      if (_newFotoProfilWebp != null) {
        payload['foto_profil_webp'] = await MultipartFile.fromFile(
          _newFotoProfilWebp!.path,
          filename: 'foto_profil.webp',
        );
      }

      final res = await _apiClient.dio.post(
        '/profile',
        data: FormData.fromMap(payload),
      );

      final updatedProfile = Map<String, dynamic>.from(res.data['data']);
      setState(() {
        _existingFotoPath = updatedProfile['foto_profil_webp'];
        _newFotoProfilWebp = null;
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
      });

      // Berikan data terbaru ke callback parent
      if (res.data['user'] != null) {
        widget.onProfileUpdated(Map<String, dynamic>.from(res.data['user']));
      } else {
        widget.onProfileUpdated(updatedProfile);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Profil & Akun berhasil diperbarui!'),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.getErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (_newFotoProfilWebp != null) {
      avatarImage = FileImage(_newFotoProfilWebp!);
    } else if (_existingFotoPath != null && _existingFotoPath!.isNotEmpty) {
      avatarImage = NetworkImage('${ApiClient.storageBaseUrl}$_existingFotoPath');
    }

    final String namaLengkap = _namaLengkapCtrl.text.isNotEmpty
        ? _namaLengkapCtrl.text
        : widget.user['name'] ?? 'Nama Santri';
    final String kamar = _kamarCtrl.text.isNotEmpty ? 'Kamar ${_kamarCtrl.text}' : 'Asrama';
    final String prodi = _prodiCtrl.text.isNotEmpty ? _prodiCtrl.text : '';
    final String kampus = _kampusCtrl.text.isNotEmpty ? _kampusCtrl.text : '';
    final List<String> subParts = [kamar];
    if (prodi.isNotEmpty || kampus.isNotEmpty) {
      subParts.add('$prodi $kampus'.trim());
    }
    final String subtitleAcademic = subParts.join(' • ');

    return Container(
      color: colorSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Avatar Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorPrimary.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: colorPrimary.withOpacity(0.35),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 104,
                          height: 104,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colorPrimary,
                                colorPrimary.withOpacity(0.4),
                                colorSecondary.withOpacity(0.6),
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: colorSurfaceContainerLowest,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? const Icon(Icons.person, size: 52, color: colorOnSurfaceVariant)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: colorPrimaryContainer,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () async {
                                final file = await ImageCompressorHelper.pickAndCompressToWebp(
                                  fromCamera: false,
                                );
                                if (file != null) {
                                  setState(() => _newFotoProfilWebp = file);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 17,
                                  color: colorOnPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      namaLengkap,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorOnSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitleAcademic.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleAcademic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: colorOnSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school, size: 14, color: colorPrimary),
                              SizedBox(width: 4),
                              Text(
                                'Santri Mahasiswa Aktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_angkatanCtrl.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorSecondaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars, size: 14, color: colorSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Angkatan ${_angkatanCtrl.text}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card 0: Kredensial & Keamanan Akun
              _buildSectionCard(
                stepNumber: '🔒',
                icon: Icons.shield_outlined,
                title: 'Kredensial & Keamanan Akun',
                children: [
                  _buildTextField(
                    _usernameCtrl,
                    'Username Login',
                    required: true,
                    prefixIcon: Icons.alternate_email,
                    prefixIconColor: colorPrimary,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'UBAH KATA SANDI (KOSONGKAN JIKA TIDAK INGIN MENGGANTI)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _currentPasswordCtrl,
                      obscureText: _obscureCurrentPassword,
                      style: const TextStyle(fontSize: 14, color: colorOnSurface),
                      decoration: _inputDecoration(
                        'Kata Sandi Saat Ini',
                        prefixIcon: Icons.lock_outline,
                        prefixIconColor: colorSecondary,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: colorOnSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                        ),
                      ),
                      validator: (val) {
                        if (_newPasswordCtrl.text.isNotEmpty && (val == null || val.isEmpty)) {
                          return 'Masukkan kata sandi saat ini untuk konfirmasi';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNewPassword,
                      style: const TextStyle(fontSize: 14, color: colorOnSurface),
                      decoration: _inputDecoration(
                        'Kata Sandi Baru (Min. 6 Karakter)',
                        prefixIcon: Icons.lock_reset,
                        prefixIconColor: colorPrimary,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: colorOnSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        ),
                      ),
                      validator: (val) {
                        if (val != null && val.isNotEmpty && val.length < 6) {
                          return 'Kata sandi baru minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card 1
              _buildSectionCard(
                stepNumber: '1',
                icon: Icons.bedroom_parent,
                title: '1. Data Personal & Asrama',
                children: [
                  _buildTextField(_namaLengkapCtrl, 'Nama Lengkap *', required: true),
                  _buildTextField(_namaPanggilanCtrl, 'Nama Panggilan'),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JENIS KELAMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorOnSurfaceVariant,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _jenisKelamin,
                              dropdownColor: colorSurfaceContainerLow,
                              style: const TextStyle(fontSize: 14, color: colorOnSurface),
                              decoration: _inputDecoration('Jenis Kelamin'),
                              items: const [
                                DropdownMenuItem(value: 'L', child: Text('Laki-laki (L)')),
                                DropdownMenuItem(value: 'P', child: Text('Perempuan (P)')),
                              ],
                              onChanged: (v) => setState(() => _jenisKelamin = v ?? 'L'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_kamarCtrl, 'Kamar Asrama'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _noWaSantriCtrl,
                    'No. WhatsApp Santri',
                    isPhone: true,
                    prefixIcon: Icons.chat,
                    prefixIconColor: colorPrimary,
                  ),
                  _buildTextField(_namaBapakCtrl, 'Nama Bapak'),
                  _buildTextField(_namaIbuCtrl, 'Nama Ibu'),
                  _buildTextField(
                    _noWaOrtuCtrl,
                    'No. WhatsApp Orang Tua',
                    isPhone: true,
                    prefixIcon: Icons.contact_phone,
                    prefixIconColor: colorSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card 2
              _buildSectionCard(
                stepNumber: '2',
                icon: Icons.mosque,
                title: '2. Data Kepesantrenan & Sambung',
                children: [
                  _buildTextField(_asalProvinsiCtrl, 'Asal Provinsi'),
                  _buildTextField(_asalKotaKabCtrl, 'Asal Kota / Kabupaten'),
                  _buildTextField(_asalDaerahCtrl, 'Asal Daerah Sambung'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_asalDesaCtrl, 'Asal Desa')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_asalKelompokCtrl, 'Asal Kelompok')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS MUBALIGH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorOnSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _statusMubaligh,
                        dropdownColor: colorSurfaceContainerLow,
                        style: const TextStyle(fontSize: 14, color: colorOnSurface),
                        decoration: _inputDecoration('Status Mubaligh'),
                        items: const [
                          DropdownMenuItem(value: 'belum', child: Text('Belum Mubaligh')),
                          DropdownMenuItem(value: 'sudah', child: Text('Sudah Mubaligh')),
                        ],
                        onChanged: (v) => setState(() => _statusMubaligh = v ?? 'belum'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card 3
              _buildSectionCard(
                stepNumber: '3',
                icon: Icons.school,
                title: '3. Data Akademik Perguruan Tinggi',
                children: [
                  _buildTextField(
                    _kampusCtrl,
                    'Nama Kampus / Universitas',
                    prefixIcon: Icons.account_balance,
                    prefixIconColor: colorPrimary,
                  ),
                  _buildTextField(_fakultasCtrl, 'Fakultas'),
                  _buildTextField(_jurusanCtrl, 'Jurusan / Departemen'),
                  _buildTextField(_prodiCtrl, 'Program Studi (Prodi)'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _angkatanCtrl,
                          'Angkatan Kuliah (YYYY)',
                          isPhone: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_beasiswaCtrl, 'Beasiswa (Opsional)'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [colorPrimaryContainer, colorInversePrimary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimaryContainer.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20, color: colorOnSurface),
                            SizedBox(width: 8),
                            Text(
                              'SIMPAN PERUBAHAN PROFIL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorOnSurface,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String stepNumber,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: colorSecondary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: colorSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorOnSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: colorSurfaceContainerHighest),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool isPhone = false,
    IconData? prefixIcon,
    Color? prefixIconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorOnSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: colorOnSurface),
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            decoration: _inputDecoration(
              label,
              prefixIcon: prefixIcon,
              prefixIconColor: prefixIconColor,
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
                : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? prefixIcon,
    Color? prefixIconColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: colorSurfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: prefixIconColor ?? colorPrimary)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: colorPrimary, width: 1),
      ),
    );
  }
}