import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/excel_exporter_helper.dart';
import '../../core/image_compressor_helper.dart';

class SantriMateriTab extends StatefulWidget {
  final Map<String, dynamic> user;

  const SantriMateriTab({super.key, required this.user});

  @override
  State<SantriMateriTab> createState() => _SantriMateriTabState();
}

class _SantriMateriTabState extends State<SantriMateriTab> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _selectedFilterStatus;
  List<dynamic> _progresList = [];
  List<dynamic> _capaianDatabaseLogs = [];
  List<dynamic> _masterAlquran = [];
  List<dynamic> _masterHadits = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchMasterData(),
      _fetchMyProgres(),
    ]);
  }

  Future<void> _fetchMasterData() async {
    try {
      final res = await _apiClient.dio.get('/materi/master-data');
      if (mounted) {
        setState(() {
          _masterAlquran = res.data['data']['alquran'] ?? [];
          _masterHadits = res.data['data']['hadits'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMyProgres() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        '/materi/progres-saya',
        queryParameters: _selectedFilterStatus != null
            ? {'status_validasi': _selectedFilterStatus}
            : null,
      );
      final capRes = await _apiClient.dio.get('/materi/database-capaian');
      if (mounted) {
        setState(() {
          _progresList = res.data['data']['data'] ?? [];
          _capaianDatabaseLogs = capRes.data['data']['data'] ?? [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.getErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _extractFotoList(dynamic rawFoto) {
    if (rawFoto == null) return [];
    if (rawFoto is List) {
      return rawFoto.map((e) => e.toString()).toList();
    }
    final str = rawFoto.toString().trim();
    if (str.startsWith('[')) {
      try {
        final List<dynamic> parsed = jsonDecode(str);
        return parsed.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    if (str.isNotEmpty) {
      return [str];
    }
    return [];
  }

  Future<void> _handleUploadKitab(Map<String, dynamic> progresItem) async {
    List<PickedCompressedImage> selectedImages = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color sheetBg = isDark ? const Color(0xFF161D18) : Colors.white;
        final Color boxBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
        final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
        final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
        const Color primaryCyan = Color(0xFF53D9DC);
        const Color secondaryGold = Color(0xFFEDBF70);

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              color: sheetBg,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: primaryCyan.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_library, size: 18, color: primaryCyan),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Upload Foto Halaman Kitab',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedImages.length} Foto Terpilih',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryCyan),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih sumber foto: potret satu per satu atau ambil banyak halaman langsung dari galeri.',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    if (selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final img = selectedImages[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    img.bytes,
                                    width: 100,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Hal ${index + 1}',
                                      style: const TextStyle(color: secondaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () => setStateSheet(() => selectedImages.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: boxBg,
                              foregroundColor: primaryCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              final img = await ImageCompressorHelper.pickBytesUniversal(fromCamera: true);
                              if (img != null) setStateSheet(() => selectedImages.add(img));
                            },
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('Kamera (+1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: boxBg,
                              foregroundColor: secondaryGold,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              final imgs = await ImageCompressorHelper.pickMultipleBytesUniversal();
                              if (imgs.isNotEmpty) setStateSheet(() => selectedImages.addAll(imgs));
                            },
                            icon: const Icon(Icons.collections, size: 18),
                            label: const Text('Galeri (Banyak)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: selectedImages.isEmpty
                            ? null
                            : const LinearGradient(colors: [Color(0xFF12B3B6), Color(0xFF00696B)]),
                        color: selectedImages.isEmpty ? Colors.grey.withValues(alpha: 0.2) : null,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: selectedImages.isEmpty
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _uploadBatchImages(progresItem['id'], selectedImages);
                              },
                        child: Text(
                          selectedImages.isEmpty ? 'PILIH FOTO DAHULU' : 'KIRIM ${selectedImages.length} FOTO BUKTI KITAB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedImages.isEmpty ? onSurfaceVariant : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _uploadBatchImages(int progresId, List<PickedCompressedImage> images) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Mengunggah foto lembar kitab...', style: TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );

    try {
      final List<MultipartFile> files = images
          .map((img) => MultipartFile.fromBytes(img.bytes, filename: img.filename))
          .toList();

      final formData = FormData();
      for (final f in files) {
        formData.files.add(MapEntry('foto_kitab_webp[]', f));
      }

      final res = await _apiClient.dio.post(
        '/materi/progres/$progresId/upload',
        data: formData,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Foto bukti berhasil diunggah!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _fetchMyProgres();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.getErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _showFormInputCapaianMandiri() async {
    String jenisMateri = 'alquran';
    int? selectedGuruId;
    int? selectedSurahId = _masterAlquran.isNotEmpty ? _masterAlquran.first['id'] : 1;
    int? selectedHaditsId = _masterHadits.isNotEmpty ? _masterHadits.first['id'] : null;

    final ayatAwalCtrl = TextEditingController(text: '1');
    final ayatAkhirCtrl = TextEditingController(text: '10');
    final halAwalCtrl = TextEditingController(text: '1');
    final halAkhirCtrl = TextEditingController(text: '2');
    final catatanCtrl = TextEditingController();
    bool isSubmitting = false;

    List<dynamic> guruList = [];
    try {
      final res = await _apiClient.dio.get('/users/daftar-guru');
      guruList = res.data['data'] ?? [];
      if (guruList.isNotEmpty) {
        selectedGuruId = guruList.first['id'];
      }
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color sheetBg = isDark ? const Color(0xFF161D18) : Colors.white;
        final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
        final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              color: sheetBg,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Catat Capaian Materi Mandiri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih materi yang telah selesai disimak beserta Dewan Guru verifikator.',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedGuruId,
                      dropdownColor: sheetBg,
                      decoration: const InputDecoration(
                        labelText: 'Dewan Guru Verifikator',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: guruList.map<DropdownMenuItem<int>>((g) {
                        final roleLabel = g['is_asisten_guru'] == true ? 'Asisten Guru' : (g['role'] ?? 'Guru');
                        return DropdownMenuItem<int>(
                          value: g['id'],
                          child: Text('${g['username']} ($roleLabel)'),
                        );
                      }).toList(),
                      onChanged: (v) => setStateModal(() => selectedGuruId = v),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'alquran', label: Text('Al-Qur\'an')),
                        ButtonSegment(value: 'hadits', label: Text('Al-Hadits / Kitab')),
                      ],
                      selected: {jenisMateri},
                      onSelectionChanged: (v) => setStateModal(() => jenisMateri = v.first),
                    ),
                    const SizedBox(height: 14),
                    if (jenisMateri == 'alquran') ...[
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: selectedSurahId,
                        dropdownColor: sheetBg,
                        decoration: const InputDecoration(labelText: 'Pilih Surah (1-114)', border: OutlineInputBorder()),
                        items: _masterAlquran.map<DropdownMenuItem<int>>((s) {
                          return DropdownMenuItem<int>(
                            value: s['id'],
                            child: Text('${s['id']}. ${s['nama_surah']} (${s['total_ayat']} Ayat)'),
                          );
                        }).toList(),
                        onChanged: (v) => setStateModal(() => selectedSurahId = v),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ayatAwalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Ayat Awal', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                        dropdownColor: sheetBg,
                        decoration: const InputDecoration(labelText: 'Pilih Kitab Hadits', border: OutlineInputBorder()),
                        items: _masterHadits.map<DropdownMenuItem<int>>((h) {
                          return DropdownMenuItem<int>(
                            value: h['id'],
                            child: Text('${h['nama_kitab']} (Maks ${h['maksimal_halaman']} Hal)'),
                          );
                        }).toList(),
                        onChanged: (v) => setStateModal(() => selectedHaditsId = v),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: halAwalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Halaman Awal', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: halAkhirCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Halaman Akhir', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: catatanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Setoran (Opsional)',
                        border: OutlineInputBorder(),
                      ),
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
                              if (selectedGuruId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pilih Dewan Guru verifikator terlebih dahulu!')),
                                );
                                return;
                              }
                              setStateModal(() => isSubmitting = true);
                              try {
                                final Map<String, dynamic> payload = {
                                  'jenis_materi': jenisMateri,
                                  'guru_id': selectedGuruId,
                                  'catatan': catatanCtrl.text.trim(),
                                };
                                if (jenisMateri == 'alquran') {
                                  payload['surah_id'] = selectedSurahId;
                                  payload['ayat_awal'] = int.tryParse(ayatAwalCtrl.text.trim());
                                  payload['ayat_akhir'] = int.tryParse(ayatAkhirCtrl.text.trim());
                                } else {
                                  payload['hadits_id'] = selectedHaditsId;
                                  payload['halaman_awal'] = int.tryParse(halAwalCtrl.text.trim());
                                  payload['halaman_akhir'] = int.tryParse(halAkhirCtrl.text.trim());
                                }
                                final res = await _apiClient.dio.post('/materi/santri-input', data: payload);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.data['message'] ?? 'Berhasil dicatat, menunggu validasi guru'),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _fetchMyProgres();
                              } catch (e) {
                                setStateModal(() => isSubmitting = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ApiClient.getErrorMessage(e))),
                                );
                              }
                            },
                      child: const Text('KIRIM KE VERIFIKATOR GURU', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDatabaseCapaianModal() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
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
                  const Icon(Icons.verified_rounded, color: primaryCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Database Capaian Materi (Tuntas & Tervalidasi)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: _capaianDatabaseLogs.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada materi yang tercatat di database capaian.',
                          style: TextStyle(color: onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _capaianDatabaseLogs.length,
                        itemBuilder: (context, i) {
                          final log = _capaianDatabaseLogs[i];
                          final tingkatan = (log['tingkatan_kelas'] ?? '')
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log['judul_materi'] ?? '',
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
                                  '${log['detail_capaian']}\nValidator: ${log['validator']?['username'] ?? 'Guru'}${log['catatan'] != null && log['catatan'].toString().isNotEmpty ? '\nCatatan: ${log['catatan']}' : ''}',
                                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    (log['tanggal_validasi'] ?? '').toString().split('T').first,
                                    style: TextStyle(fontSize: 10, color: onSurfaceVariant),
                                  ),
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

    final int totalItem = _progresList.length;
    final int totalTervalidasi = _capaianDatabaseLogs.length;
    final int totalHutang = _progresList
        .where((e) => e['status_validasi'] == 'belum_setor' || e['status_validasi'] == 'ditolak')
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_santri_catat_materi',
        backgroundColor: const Color(0xFF12B3B6),
        foregroundColor: Colors.black,
        onPressed: _showFormInputCapaianMandiri,
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('Catat Capaian Mandiri', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyProgres,
        child: Column(
          children: [
            // 1. Top Summary Banner (Hero Progress Card dari Stitch)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 16, color: secondaryGold),
                          const SizedBox(width: 6),
                          Text('Target Kurikulum Santri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Aktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryCyan)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 3 Key Metrics Columns
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Total Target', '$totalItem', onSurface),
                        Container(width: 1, height: 32, color: outlineColor.withValues(alpha: 0.3)),
                        _buildStatColumn('Tuntas', '$totalTervalidasi', secondaryGold),
                        Container(width: 1, height: 32, color: outlineColor.withValues(alpha: 0.3)),
                        _buildStatColumn('Hutang / Revisi', '$totalHutang', const Color(0xFFFFB4AB)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Shortcut ke Database Capaian Tervalidasi
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A4A01).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryGold.withValues(alpha: 0.4)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _showDatabaseCapaianModal,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_special, size: 16, color: secondaryGold),
                            SizedBox(width: 8),
                            Text(
                              'Buka Database Capaian Tervalidasi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryGold),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right, size: 16, color: secondaryGold),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Horizontal Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip(null, 'Semua ($totalItem)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('belum_setor', 'Hutang (Belum Setor)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ditolak', 'Ditolak / Revisi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('menunggu_validasi', 'Menunggu Validasi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('tervalidasi_penuh', 'Tervalidasi'),
                ],
              ),
            ),

            // 3. Feed Target Materi Cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _progresList.isEmpty
                      ? Center(
                          child: Text('Tidak ada target materi pada filter ini.', style: TextStyle(color: onSurfaceVariant)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _progresList.length,
                          itemBuilder: (context, index) {
                            final item = _progresList[index];
                            final target = item['target_harian'] ?? {};
                            final String jenis = target['jenis_materi'] ?? 'alquran';
                            final String status = item['status_validasi'] ?? 'belum_setor';
                            final String tanggal = (target['tanggal'] ?? '').toString().split('T').first;
                            final List<String> fotoPaths = _extractFotoList(item['foto_kitab_webp']);

                            String judulMateri = '';
                            String detailTarget = '';
                            if (jenis == 'alquran') {
                              final namaSurah = target['surah']?['nama_surah'] ?? 'Surah #${target['surah_id']}';
                              judulMateri = 'Al-Qur\'an: Surah $namaSurah';
                              detailTarget = 'Ayat ${target['ayat_awal']} s/d ${target['ayat_akhir']}';
                            } else {
                              final namaKitab = target['hadits']?['nama_kitab'] ?? 'Kitab Hadits';
                              judulMateri = 'Hadits: $namaKitab';
                              detailTarget =
                                  'Hal. ${target['halaman_awal']} (Baris ${target['baris_awal']}) s/d Hal. ${target['halaman_akhir']} (Baris ${target['baris_akhir']})';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: status == 'ditolak'
                                      ? const Color(0xFF93000A).withValues(alpha: 0.5)
                                      : (status == 'tervalidasi_penuh'
                                          ? primaryCyan.withValues(alpha: 0.3)
                                          : outlineColor.withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: secondaryGold.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                jenis == 'alquran' ? Icons.auto_stories : Icons.menu_book,
                                                size: 18,
                                                color: secondaryGold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                judulMateri,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Detail box
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.import_contacts, size: 16, color: primaryCyan),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            detailTarget,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tanggal Target: $tanggal',
                                    style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                  ),
                                  // Catatan penolakan jika ditolak
                                  if (status == 'ditolak' && item['catatan_penolakan'] != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF93000A).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFFB4AB).withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.announcement, size: 16, color: Color(0xFFFFB4AB)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Catatan Guru: ${item['catatan_penolakan']}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFFFFB4AB)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  // Pratinjau Foto
                                  if (fotoPaths.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 110,
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
                                              title: '$judulMateri (Halaman ${i + 1})',
                                            ),
                                            child: Stack(
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    '${ApiClient.storageBaseUrl}$path',
                                                    width: 85,
                                                    height: 110,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.all(4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                  // Tombol Setor / Revisi
                                  if (status != 'tervalidasi_penuh') ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: status == 'ditolak'
                                              ? const Color(0xFF93000A)
                                              : const Color(0xFF12B3B6),
                                          foregroundColor: status == 'ditolak' ? Colors.white : Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _handleUploadKitab(item),
                                        icon: Icon(
                                          status == 'ditolak' ? Icons.refresh : Icons.photo_camera,
                                          size: 16,
                                        ),
                                        label: Text(
                                          status == 'belum_setor' ? 'Setor Foto Kitab' : 'Upload Ulang Foto Revisi',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFBBC9C9))),
      ],
    );
  }

  Widget _buildFilterChip(String? statusValue, String label) {
    final bool isSelected = _selectedFilterStatus == statusValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : const Color(0xFFDDE5DC))),
      selected: isSelected,
      selectedColor: const Color(0xFF53D9DC),
      backgroundColor: const Color(0xFF161D18),
      onSelected: (_) {
        setState(() => _selectedFilterStatus = statusValue);
        _fetchMyProgres();
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'tervalidasi_penuh':
        bg = const Color(0xFF53D9DC).withValues(alpha: 0.15);
        fg = const Color(0xFF53D9DC);
        text = 'TERVALIDASI';
        break;
      case 'menunggu_validasi':
        bg = const Color(0xFF7AD5D7).withValues(alpha: 0.15);
        fg = const Color(0xFF7AD5D7);
        text = 'MENUNGGU';
        break;
      case 'ditolak':
        bg = const Color(0xFFFFB4AB).withValues(alpha: 0.2);
        fg = const Color(0xFFFFB4AB);
        text = 'REVISI';
        break;
      default:
        bg = const Color(0xFFEDBF70).withValues(alpha: 0.15);
        fg = const Color(0xFFEDBF70);
        text = 'BELUM SETOR';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}