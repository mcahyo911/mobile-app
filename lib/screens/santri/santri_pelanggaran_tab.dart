import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/image_compressor_helper.dart';

class SantriPelanggaranTab extends StatefulWidget {
  final Map<String, dynamic> user;

  const SantriPelanggaranTab({super.key, required this.user});

  @override
  State<SantriPelanggaranTab> createState() => _SantriPelanggaranTabState();
}

class _SantriPelanggaranTabState extends State<SantriPelanggaranTab> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  File? _buktiFotoWebp;
  bool _isSubmitting = false;
  bool _isPledgeChecked = false;
  bool _isGuideExpanded = true;
  String _selectedCategory = 'Jam Malam & Izin';

  final List<String> _categories = [
    'Jam Malam & Izin',
    'Adab & Asrama',
    'Ketertiban Sholat',
    'Lainnya',
  ];

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final file = await ImageCompressorHelper.pickAndCompressToWebp(
      fromCamera: fromCamera,
    );
    if (file != null) {
      setState(() => _buktiFotoWebp = file);
    }
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPledgeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon centang pernyataan komitmen kejujuran terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String fullDeskripsi = '[$_selectedCategory] ${_deskripsiController.text.trim()}';

      final Map<String, dynamic> mapData = {
        'deskripsi': fullDeskripsi,
      };

      if (_buktiFotoWebp != null) {
        mapData['bukti_foto_webp'] = await MultipartFile.fromFile(
          _buktiFotoWebp!.path,
          filename: 'bukti_pelanggaran.webp',
        );
      }

      final res = await _apiClient.dio.post(
        '/pelanggaran',
        data: FormData.fromMap(mapData),
      );

      if (!mounted) return;
      _deskripsiController.clear();
      setState(() {
        _buktiFotoWebp = null;
        _isPledgeChecked = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.data['message'] ?? 'Laporan anonim berhasil dikirim aman.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.getErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color primaryContainer = Color(0xFF12B3B6);
    const Color secondaryGold = Color(0xFFEDBF70);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Banner / Service Title & Encrypted Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, size: 20, color: primaryCyan),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Layanan Pengaduan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            Text(
                              'Sistem Pelaporan Disiplin & Etika Santri',
                              style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A4A01).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: secondaryGold.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: secondaryGold),
                      SizedBox(width: 4),
                      Text(
                        'Terenkripsi',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryGold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Hero Privacy & Whistleblower Shield Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryCyan.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: primaryCyan.withValues(alpha: isDark ? 0.05 : 0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryContainer.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: primaryCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jaminan Kerahasiaan 100% Anonim',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Identitas akun Anda otomatis disembunyikan oleh sistem dari Dewan Guru & Pengurus Pondok. Hanya kronologi objektif dan bukti otentik yang diteruskan untuk verifikasi musyawarah.',
                              style: TextStyle(fontSize: 12, color: onSurfaceVariant, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF93000A).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_top, size: 12, color: Color(0xFFFFB4AB)),
                            SizedBox(width: 4),
                            Text(
                              'Maks. 3 Laporan / Hari',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFB4AB)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF242C26) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.key, size: 12, color: secondaryGold),
                            SizedBox(width: 4),
                            Text(
                              'Enkripsi Data SHA-256',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryGold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Main Complaint Form Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, size: 18, color: primaryCyan),
                        const SizedBox(width: 8),
                        Text(
                          'Formulir Pengaduan Anonim',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                        ),
                        const Spacer(),
                        Icon(Icons.info_outline, size: 18, color: onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kategori Pelanggaran
                    Text(
                      'Pilih Kategori Pelanggaran *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _categories.map((cat) {
                        final bool isSelected = _selectedCategory == cat;
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryContainer.withValues(alpha: 0.2) : inputBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? primaryCyan : outlineColor.withValues(alpha: 0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat == 'Jam Malam & Izin'
                                      ? Icons.schedule
                                      : (cat == 'Adab & Asrama'
                                          ? Icons.meeting_room
                                          : (cat == 'Ketertiban Sholat' ? Icons.mosque : Icons.more_horiz)),
                                  size: 14,
                                  color: isSelected ? primaryCyan : onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? primaryCyan : onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Field Kronologi Kejadian
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kronologi Kejadian & Terlapor *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _deskripsiController,
                          builder: (context, value, _) {
                            final int len = value.text.length;
                            return Text(
                              '$len / 500',
                              style: TextStyle(
                                fontSize: 11,
                                color: len >= 10 ? primaryCyan : onSurfaceVariant,
                                fontWeight: len >= 10 ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 5,
                      maxLength: 500,
                      style: TextStyle(color: onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        counterText: '',
                        hintText:
                            'Jelaskan perkiraan waktu, lokasi pondok/kamar, serta nama santri yang dilaporkan secara runtut dan objektif...',
                        hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 10) {
                          return 'Mohon jelaskan kronologi minimal 10 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Minimal 10 karakter', style: TextStyle(fontSize: 10, color: onSurfaceVariant)),
                        const Row(
                          children: [
                            Icon(Icons.lock, size: 12, color: primaryCyan),
                            SizedBox(width: 4),
                            Text(
                              'Identitas Anda Terlindungi',
                              style: TextStyle(fontSize: 10, color: primaryCyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lampiran Foto Bukti
                    Text(
                      'Lampiran Foto Bukti (Opsional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    if (_buktiFotoWebp != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryCyan.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _buktiFotoWebp!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _buktiFotoWebp!.path.split('/').last,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(_buktiFotoWebp!.lengthSync() / 1024).toStringAsFixed(1)} KB • WebP',
                                    style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 2),
                                  const Row(
                                    children: [
                                      Icon(Icons.security, size: 11, color: primaryCyan),
                                      SizedBox(width: 4),
                                      Text(
                                        'Metadata EXIF Dihapus',
                                        style: TextStyle(fontSize: 10, color: primaryCyan, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Hapus Foto',
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                              onPressed: () => setState(() => _buktiFotoWebp = null),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inputBg,
                              foregroundColor: primaryCyan,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () => _pickImage(true),
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('Ambil Kamera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inputBg,
                              foregroundColor: onSurface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () => _pickImage(false),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Buka Galeri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Anti-Fitnah Pledge & Checkbox
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: outlineColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _isPledgeChecked,
                              activeColor: primaryContainer,
                              checkColor: Colors.black,
                              side: BorderSide(color: outlineColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _isPledgeChecked = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPledgeChecked = !_isPledgeChecked),
                              child: Text(
                                'Saya bersumpah atas nama Allah SWT bahwa laporan ini dibuat dengan sebenar-benarnya tanpa motif fitnah, kebencian pribadi, maupun rekayasa kejadian.',
                                style: TextStyle(fontSize: 11, color: onSurfaceVariant, height: 1.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Primary Submit CTA Button
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submitLaporan,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'KIRIM LAPORAN ANONIM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.1,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Guidelines Sub-card (Panduan & Batasan Pelaporan)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isGuideExpanded = !_isGuideExpanded),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book, size: 18, color: secondaryGold),
                            const SizedBox(width: 8),
                            Text(
                              'Panduan & Batasan Pelaporan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
                            ),
                          ],
                        ),
                        Icon(
                          _isGuideExpanded ? Icons.expand_more : Icons.chevron_right,
                          color: onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  if (_isGuideExpanded) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: outlineColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'Laporan yang memenuhi syarat peninjauan langsung Majelis Disiplin:',
                      style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    _buildGuideItem('Pelanggaran jam malam berulang atau meninggalkan asrama tanpa surat izin resmi dari keamanan.'),
                    const SizedBox(height: 6),
                    _buildGuideItem('Perusakan fasilitas umum pondok, pelanggaran kebersihan berat, atau kelalaian adab taklim.'),
                    const SizedBox(height: 6),
                    _buildGuideItem('Tindakan perundungan (bullying), pertengkaran fisik, atau pelanggaran syariat di lingkungan pondok.'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.star, size: 14, color: Color(0xFFEDBF70)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFFBBC9C9), height: 1.35),
          ),
        ),
      ],
    );
  }
}