import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/excel_exporter_helper.dart';
import '../../core/image_compressor_helper.dart';
import '../../core/location_helper.dart';

class SantriPresensiTab extends StatefulWidget {
  final Map<String, dynamic> user;

  const SantriPresensiTab({super.key, required this.user});

  @override
  State<SantriPresensiTab> createState() => _SantriPresensiTabState();
}

class _SantriPresensiTabState extends State<SantriPresensiTab> {
  final ApiClient _apiClient = ApiClient();
  int _subTabIndex = 0;

  bool _isLoading = true;
  bool _onlyToday = true;
  String? _selectedKategori;
  List<dynamic> _sessions = [];

  final Map<int, String> _localSubmittedStatus = {};
  final Map<int, String> _localApprovalStatus = {};

  bool _isLoadingIzinKeluar = true;
  List<dynamic> _myIzinKeluarList = [];

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
    _fetchMyIzinKeluar();
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

  String _formatDateTimeWita(dynamic rawDateTime) {
    if (rawDateTime == null) return '-';
    final String str = rawDateTime.toString();
    final DateTime? parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return '${DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal())} WITA';
    }
    return str;
  }

  Map<String, String?> _getMyAttendanceStatus(
    Map<String, dynamic> session,
    bool isClosed,
  ) {
    final int sessionId = session['id'] ?? 0;
    final int myUserId = widget.user['id'] ?? 0;

    String? status;
    String? approval;

    if (session['my_status'] != null) {
      status = session['my_status'].toString();
      approval = session['my_approval_status']?.toString();
    } else if (session['status_kehadiran_saya'] != null) {
      status = session['status_kehadiran_saya'].toString();
    } else if (session['my_record'] is Map) {
      status = session['my_record']['status']?.toString();
      approval = session['my_record']['status_approval_izin']?.toString();
    }

    if (status == null && session['records'] is List) {
      for (final r in (session['records'] as List)) {
        if (r is Map &&
            (r['user_id'] == myUserId ||
                r['santri_id'] == myUserId ||
                r['santri']?['id'] == myUserId)) {
          status = r['status']?.toString();
          approval = r['status_approval_izin']?.toString();
          break;
        }
      }
    }

    if (_localSubmittedStatus.containsKey(sessionId)) {
      status = _localSubmittedStatus[sessionId];
      approval = _localApprovalStatus[sessionId] ?? approval;
    }

    if (status == 'alpha' && !isClosed) {
      status = null;
    }

    if (status == null && isClosed) {
      status = 'alpha';
    }

    return {
      'status': status,
      'approval': approval,
    };
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> queryParams = {};
      if (_selectedKategori != null) {
        queryParams['kategori'] = _selectedKategori;
      }

      final response = await _apiClient.dio.get(
        '/presensi/sessions',
        queryParameters: queryParams,
      );

      final paginatedData = response.data['data'];
      final List<dynamic> allSessions = paginatedData['data'] ?? [];
      final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final List<dynamic> filteredSessions = _onlyToday
          ? allSessions
              .where((s) => _extractLocalDate(s['tanggal']) == todayStr)
              .toList()
          : allSessions;

      final int myUserId = widget.user['id'] ?? 0;
      for (final s in filteredSessions) {
        final int sId = s['id'] ?? 0;
        if (s['records'] == null && s['my_status'] == null && sId != 0) {
          try {
            final detailRes = await _apiClient.dio.get('/presensi/sessions/$sId');
            final List<dynamic> recs = detailRes.data['data']?['records'] ?? [];
            for (final r in recs) {
              if (r is Map &&
                  (r['user_id'] == myUserId ||
                      r['santri_id'] == myUserId ||
                      r['santri']?['id'] == myUserId)) {
                final String? recStatus = r['status']?.toString();
                final String? recApproval = r['status_approval_izin']?.toString();
                if (recStatus != null) {
                  _localSubmittedStatus[sId] = recStatus;
                }
                if (recApproval != null) {
                  _localApprovalStatus[sId] = recApproval;
                }
                break;
              }
            }
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _sessions = filteredSessions;
      });
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

  Future<void> _fetchMyIzinKeluar() async {
    setState(() => _isLoadingIzinKeluar = true);
    try {
      final res = await _apiClient.dio.get('/izin-keluar/saya');
      setState(() {
        _myIzinKeluarList = res.data['data']['data'] ?? [];
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingIzinKeluar = false);
    }
  }

  Future<void> _showInputTokenDialog(Map<String, dynamic> session) async {
    final tokenController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
        final Color boxBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
        final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
        final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
        const Color primaryCyan = Color(0xFF53D9DC);
        const Color secondaryGold = Color(0xFFEDBF70);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final String currentText = tokenController.text;

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? const Color(0xFF3C4949) : Colors.black12),
              ),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: secondaryGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pin_outlined, color: secondaryGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verifikasi 6-Digit Token',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _kategoriLabels[session['kategori']] ?? session['kategori'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: primaryCyan, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lihat display proyektor atau tanyakan Dewan Guru pengampu:',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    // 6 Box Angka Mandiri
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final String digit =
                              index < currentText.length ? currentText[index] : '';
                          final bool isCurrent = index == currentText.length;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 44,
                            height: 56,
                            decoration: BoxDecoration(
                              color: boxBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent
                                    ? secondaryGold
                                    : (digit.isNotEmpty ? primaryCyan : (isDark ? const Color(0xFF3C4949) : Colors.black12)),
                                width: isCurrent ? 2 : 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                digit,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: digit.isNotEmpty ? primaryCyan : onSurface,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hidden real input field
                    Opacity(
                      opacity: 0.0,
                      child: SizedBox(
                        height: 0,
                        child: TextField(
                          autofocus: true,
                          controller: tokenController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (_) => setStateDialog(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: onSurfaceVariant)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B3B6),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (tokenController.text.trim().length != 6) return;
                          setStateDialog(() => isSubmitting = true);
                          try {
                            final res = await _apiClient.dio.post(
                              '/presensi/hadir',
                              data: {
                                'session_id': session['id'],
                                'token': tokenController.text.trim(),
                              },
                            );
                            if (!mounted) return;
                            setState(() {
                              _localSubmittedStatus[session['id']] = 'hadir';
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.data['message'] ?? 'Presensi berhasil!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                            _fetchSessions();
                          } catch (e) {
                            setStateDialog(() => isSubmitting = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ApiClient.getErrorMessage(e)),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.how_to_reg, size: 18),
                  label: const Text('KIRIM PRESENSI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<PickedCompressedImage?> _pickImageWithSourceSelection() async {
    final bool? fromCamera = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: Text(
                'Pilih Sumber Foto Bukti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF12B3B6)),
              title: const Text('Ambil Foto Langsung (Kamera)'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFEDBF70)),
              title: const Text('Pilih dari Galeri HP'),
              onTap: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (fromCamera == null) return null;
    return await ImageCompressorHelper.pickBytesUniversal(fromCamera: fromCamera);
  }

  Future<void> _showAjukanIzinModal(Map<String, dynamic> session) async {
    String selectedStatus = 'izin';
    final alasanController = TextEditingController();
    PickedCompressedImage? pickedImg;
    bool isSubmitting = false;

    LocationResult? currentLocation;
    bool isLoadingLoc = true;
    String locErrorMessage = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            void triggerFetchLocation() {
              setStateModal(() {
                isLoadingLoc = true;
                locErrorMessage = '';
              });
              LocationHelper.getCurrentLocationWithAddress().then((loc) {
                setStateModal(() {
                  currentLocation = loc;
                  isLoadingLoc = false;
                });
              }).catchError((err) {
                setStateModal(() {
                  isLoadingLoc = false;
                  locErrorMessage = err.toString().replaceAll('Exception: ', '');
                });
              });
            }

            if (isLoadingLoc && currentLocation == null && locErrorMessage.isEmpty) {
              triggerFetchLocation();
            }

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
                    Text(
                      'Ajukan Izin / Sakit (${_kategoriLabels[session['kategori']] ?? ''})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isLoadingLoc ? null : () => triggerFetchLocation(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: currentLocation != null
                              ? const Color(0xFF161D18)
                              : const Color(0xFF09100B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentLocation != null
                                ? const Color(0xFF53D9DC).withValues(alpha: 0.5)
                                : const Color(0xFF3C4949),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              currentLocation != null
                                  ? Icons.location_on_rounded
                                  : Icons.my_location_rounded,
                              size: 20,
                              color: currentLocation != null
                                  ? const Color(0xFF53D9DC)
                                  : const Color(0xFFEDBF70),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: isLoadingLoc
                                  ? const Text(
                                      'Mendeteksi titik koordinat & alamat GPS...',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFBBC9C9)),
                                    )
                                  : Text(
                                      currentLocation != null
                                          ? 'Lokasi Saat Ini:\n${currentLocation!.alamatLengkap}'
                                          : (locErrorMessage.isNotEmpty
                                              ? '$locErrorMessage\n(Klik untuk coba lagi)'
                                              : 'Klik untuk aktifkan & deteksi lokasi GPS.'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: currentLocation != null
                                            ? const Color(0xFFDDE5DC)
                                            : Colors.amber.shade200,
                                      ),
                                    ),
                            ),
                            if (isLoadingLoc)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'izin', label: Text('Izin')),
                        ButtonSegment(value: 'sakit', label: Text('Sakit')),
                      ],
                      selected: {selectedStatus},
                      onSelectionChanged: (val) =>
                          setStateModal(() => selectedStatus = val.first),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: alasanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Alasan Lengkap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        pickedImg == null
                            ? 'Lampirkan Foto Bukti'
                            : 'Foto Terpilih: ${pickedImg!.filename}',
                      ),
                      onPressed: () async {
                        final img = await _pickImageWithSourceSelection();
                        if (img != null) {
                          setStateModal(() => pickedImg = img);
                        }
                      },
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
                              if (alasanController.text.trim().isEmpty || pickedImg == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Alasan dan Foto Bukti wajib diisi!')),
                                );
                                return;
                              }
                              setStateModal(() => isSubmitting = true);
                              try {
                                LocationResult? finalLoc = currentLocation;
                                if (finalLoc == null) {
                                  try {
                                    finalLoc = await LocationHelper.getCurrentLocationWithAddress();
                                  } catch (_) {}
                                }

                                String finalAlasan = alasanController.text.trim();
                                if (finalLoc != null) {
                                  finalAlasan +=
                                      '\n[Lokasi GPS Saat Izin: ${finalLoc.alamatLengkap} (${finalLoc.latitude.toStringAsFixed(6)}, ${finalLoc.longitude.toStringAsFixed(6)})]';
                                }

                                final formData = FormData.fromMap({
                                  'session_id': session['id'],
                                  'status': selectedStatus,
                                  'alasan_izin': finalAlasan,
                                  'bukti_izin_webp': MultipartFile.fromBytes(
                                    pickedImg!.bytes,
                                    filename: pickedImg!.filename,
                                  ),
                                });

                                final res = await _apiClient.dio.post(
                                  '/presensi/izin',
                                  data: formData,
                                );

                                if (!mounted) return;
                                setState(() {
                                  _localSubmittedStatus[session['id']] = selectedStatus;
                                  _localApprovalStatus[session['id']] = 'pending';
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.data['message'] ?? 'Izin terkirim'),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _fetchSessions();
                              } catch (e) {
                                setStateModal(() => isSubmitting = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ApiClient.getErrorMessage(e)),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            },
                      child: const Text('KIRIM PERMOHONAN IZIN', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _showFormIzinKeluarModal() async {
    final DateTime now = DateTime.now();
    DateTime tanggalKeluar = now.hour < 4 ? now.subtract(const Duration(days: 1)) : now;
    DateTime tanggalKembali = now;

    String jenisIzin = 'keluar_pondok';
    final keperluanCtrl = TextEditingController();
    final waktuKeluarCtrl = TextEditingController(text: DateFormat('HH:mm').format(now));
    final estimasiKembaliCtrl = TextEditingController(text: '22:00');
    PickedCompressedImage? buktiImg;
    bool isSubmitting = false;

    LocationResult? currentLocation;
    bool isLoadingLoc = true;
    String locErrorMessage = '';

    void syncTanggalKembaliOtomatis() {
      final String keluarStr = waktuKeluarCtrl.text.trim();
      final String kembaliStr = estimasiKembaliCtrl.text.trim();
      if (kembaliStr.compareTo(keluarStr) < 0) {
        tanggalKembali = tanggalKeluar.add(const Duration(days: 1));
      } else if (tanggalKembali.isBefore(tanggalKeluar)) {
        tanggalKembali = tanggalKeluar;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          void triggerFetchLocation() {
            setStateModal(() {
              isLoadingLoc = true;
              locErrorMessage = '';
            });
            LocationHelper.getCurrentLocationWithAddress().then((loc) {
              setStateModal(() {
                currentLocation = loc;
                isLoadingLoc = false;
              });
            }).catchError((err) {
              setStateModal(() {
                isLoadingLoc = false;
                locErrorMessage = err.toString().replaceAll('Exception: ', '');
              });
            });
          }

          if (isLoadingLoc && currentLocation == null && locErrorMessage.isEmpty) {
            triggerFetchLocation();
          }

          final String est = estimasiKembaliCtrl.text.trim();
          final String kel = waktuKeluarCtrl.text.trim();
          final bool isBedaHari = DateFormat('yyyy-MM-dd').format(tanggalKembali) !=
              DateFormat('yyyy-MM-dd').format(tanggalKeluar);

          final bool isPassing23 = jenisIzin == 'terlambat_jam_malam' ||
              isBedaHari ||
              est.compareTo(kel) < 0 ||
              (est.startsWith('23:') && est != '23:00') ||
              est.startsWith('00:') ||
              est.startsWith('01:') ||
              est.startsWith('02:') ||
              est.startsWith('03:');

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
                  const Text(
                    'Form Izin Keluar & Jam Malam (23:00 WITA)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (isPassing23)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF93000A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB4AB).withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB4AB), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'LEWAT 23:00 WITA: Pengajuan ini ditandai lewat jam malam untuk pengawasan Dewan Guru.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB4AB)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'keluar_pondok', label: Text('Keluar Biasa')),
                      ButtonSegment(value: 'terlambat_jam_malam', label: Text('> 23:00 WITA')),
                    ],
                    selected: {jenisIzin},
                    onSelectionChanged: (v) {
                      setStateModal(() {
                        jenisIzin = v.first;
                        estimasiKembaliCtrl.text = jenisIzin == 'terlambat_jam_malam' ? '23:45' : '22:00';
                        syncTanggalKembaliOtomatis();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: waktuKeluarCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Jam Keluar', border: OutlineInputBorder()),
                          onTap: () async {
                            final parts = waktuKeluarCtrl.text.split(':');
                            final initTime = parts.length >= 2
                                ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts[1]) ?? 0)
                                : TimeOfDay.now();
                            final picked = await showTimePicker(context: context, initialTime: initTime);
                            if (picked != null) {
                              setStateModal(() {
                                waktuKeluarCtrl.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                syncTanggalKembaliOtomatis();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: estimasiKembaliCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Estimasi Kembali', border: OutlineInputBorder()),
                          onTap: () async {
                            final parts = estimasiKembaliCtrl.text.split(':');
                            final initTime = parts.length >= 2
                                ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts[1]) ?? 0)
                                : TimeOfDay.now();
                            final picked = await showTimePicker(context: context, initialTime: initTime);
                            if (picked != null) {
                              setStateModal(() {
                                estimasiKembaliCtrl.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                syncTanggalKembaliOtomatis();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keperluanCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Keperluan Keluar *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      buktiImg == null ? 'Lampirkan Foto Bukti' : 'Foto: ${buktiImg!.filename}',
                    ),
                    onPressed: () async {
                      final img = await _pickImageWithSourceSelection();
                      if (img != null) setStateModal(() => buktiImg = img);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B3B6),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (keperluanCtrl.text.trim().isEmpty) return;
                            setStateModal(() => isSubmitting = true);
                            try {
                              LocationResult? finalLoc = currentLocation;
                              if (finalLoc == null) {
                                try {
                                  finalLoc = await LocationHelper.getCurrentLocationWithAddress();
                                } catch (_) {}
                              }

                              String finalKeperluan = keperluanCtrl.text.trim();
                              if (finalLoc != null) {
                                finalKeperluan +=
                                    '\n[Lokasi GPS Saat Izin: ${finalLoc.alamatLengkap} (${finalLoc.latitude.toStringAsFixed(6)}, ${finalLoc.longitude.toStringAsFixed(6)})]';
                              }

                              final Map<String, dynamic> payload = {
                                'jenis_izin': jenisIzin,
                                'tanggal': DateFormat('yyyy-MM-dd').format(tanggalKeluar),
                                'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tanggalKembali),
                                'keperluan': finalKeperluan,
                                'waktu_keluar': waktuKeluarCtrl.text.trim(),
                                'estimasi_kembali': estimasiKembaliCtrl.text.trim(),
                              };
                              if (buktiImg != null) {
                                payload['bukti_foto_webp'] = MultipartFile.fromBytes(
                                  buktiImg!.bytes,
                                  filename: buktiImg!.filename,
                                );
                              }

                              final res = await _apiClient.dio.post(
                                '/izin-keluar',
                                data: FormData.fromMap(payload),
                              );

                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.data['message'] ?? 'Izin diajukan'),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                              _fetchMyIzinKeluar();
                            } catch (e) {
                              setStateModal(() => isSubmitting = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ApiClient.getErrorMessage(e)),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          },
                    child: const Text('KIRIM PENGAJUAN IZIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _laporSudahKembali(int izinId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memverifikasi GPS di area pondok...'), duration: Duration(seconds: 2)),
      );

      final loc = await LocationHelper.getCurrentLocationWithAddress();
      final double distance = LocationHelper.getDistanceToPondok(loc.latitude, loc.longitude);

      if (distance > LocationHelper.defaultRadiusMeters) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Di Luar Area Pondok'),
            content: Text(
              'Lapor kembali ditolak. Jarak Anda saat ini ${distance.toStringAsFixed(0)} meter dari pondok (Batas: ${LocationHelper.defaultRadiusMeters.toInt()}m).',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        return;
      }

      final res = await _apiClient.dio.patch('/izin-keluar/$izinId/lapor-kembali');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Verifikasi GPS berhasil! Waktu kembali dicatat.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _fetchMyIzinKeluar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildStatusBanner(String status, String? approval, bool isDark) {
    Color textColor;
    Color bgColor;
    IconData iconData;
    String statusTitle;

    if (status == 'hadir') {
      textColor = const Color(0xFF53D9DC);
      bgColor = isDark ? const Color(0xFF09100B) : const Color(0xFFE8F2EC);
      iconData = Icons.check_circle_rounded;
      statusTitle = 'STATUS: HADIR (TERCATAT)';
    } else if (status == 'izin' || status == 'sakit') {
      textColor = status == 'izin' ? const Color(0xFF7AD5D7) : const Color(0xFFEDBF70);
      bgColor = isDark ? const Color(0xFF09100B) : const Color(0xFFFFF7EB);
      iconData = Icons.assignment_turned_in_rounded;
      final String ket = approval == 'approved'
          ? 'DISETUJUI'
          : (approval == 'rejected' ? 'DITOLAK' : 'MENUNGGU VALIDASI');
      statusTitle = 'STATUS: ${status.toUpperCase()} ($ket)';
    } else {
      textColor = const Color(0xFFFFB4AB);
      bgColor = isDark ? const Color(0xFF09100B) : const Color(0xFFFFECEB);
      iconData = Icons.cancel_rounded;
      statusTitle = 'STATUS: ALPHA (TIDAK PRESENSI)';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: textColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusTitle,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0E1510) : const Color(0xFFF4F7F5);
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Sub-Tab Switcher Pill
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.fact_check_outlined, size: 16),
                  label: Text('Presensi Sesi', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.bedtime_outlined, size: 16),
                  label: Text('Izin & Jam Malam', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_subTabIndex},
              onSelectionChanged: (v) => setState(() => _subTabIndex = v.first),
            ),
          ),
          Expanded(
            child: _subTabIndex == 0
                ? _buildPresensiKegiatanView(isDark)
                : _buildIzinKeluarView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiKegiatanView(bool isDark) {
    final Color cardColor = isDark ? const Color(0xFF161D18) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF09100B) : const Color(0xFFF0F4F1);
    final Color onSurface = isDark ? const Color(0xFFDDE5DC) : const Color(0xFF1B241D);
    final Color onSurfaceVariant = isDark ? const Color(0xFFBBC9C9) : const Color(0xFF5A6B62);
    final Color outlineColor = isDark ? const Color(0xFF3C4949) : const Color(0xFFD0DCD4);

    const Color primaryCyan = Color(0xFF53D9DC);
    const Color secondaryGold = Color(0xFFEDBF70);

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Sesi Hari Ini', style: TextStyle(fontSize: 11)),
                  selected: _onlyToday,
                  onSelected: (val) {
                    setState(() => _onlyToday = val);
                    _fetchSessions();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
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
                        hint: Text('Semua Kategori (6 Sesi)', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                        dropdownColor: cardColor,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua Kategori (6 Sesi)', style: TextStyle(fontSize: 12, color: onSurface)),
                          ),
                          ..._kategoriLabels.entries.map(
                            (e) => DropdownMenuItem<String?>(
                              value: e.key,
                              child: Text(e.value, style: TextStyle(fontSize: 12, color: onSurface)),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedKategori = val);
                          _fetchSessions();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? Center(
                        child: Text('Belum ada sesi presensi yang dibuka.', style: TextStyle(color: onSurfaceVariant)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final String kategoriKey = session['kategori'] ?? '';
                          final String label = _kategoriLabels[kategoriKey] ?? kategoriKey;
                          final String tanggal = _extractLocalDate(session['tanggal']);
                          final String waktuSelesai = (session['waktu_selesai'] ?? '23:59:59').toString();
                          final String jamSelesaiFormatted =
                              waktuSelesai.length == 5 ? '$waktuSelesai:00' : waktuSelesai;
                          final DateTime? endDateTime = DateTime.tryParse('$tanggal $jamSelesaiFormatted');
                          final bool isClosed = (session['is_closed'] == true) ||
                              (endDateTime != null && DateTime.now().isAfter(endDateTime));

                          final myAtt = _getMyAttendanceStatus(session, isClosed);
                          final String? myStatus = myAtt['status'];
                          final String? myApproval = myAtt['approval'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: myStatus == 'hadir'
                                    ? primaryCyan.withValues(alpha: 0.3)
                                    : outlineColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: primaryCyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.auto_stories, size: 18, color: primaryCyan),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: onSurface,
                                              ),
                                            ),
                                            Text(
                                              'Presensi Pengajian',
                                              style: TextStyle(fontSize: 11, color: secondaryGold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isClosed
                                            ? Colors.red.withValues(alpha: 0.15)
                                            : primaryCyan.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isClosed ? 'DITUTUP' : 'BUKA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isClosed ? Colors.redAccent : primaryCyan,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: secondaryGold),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$tanggal • ${session['waktu_mulai']} - ${session['waktu_selesai']} WITA',
                                        style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (myStatus != null)
                                  _buildStatusBanner(myStatus, myApproval, isDark)
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: outlineColor.withValues(alpha: 0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: () => _showAjukanIzinModal(session),
                                          icon: const Icon(Icons.event_busy, size: 16),
                                          label: const Text('Izin / Sakit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF12B3B6),
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: () => _showInputTokenDialog(session),
                                          icon: const Icon(Icons.dialpad, size: 16),
                                          label: const Text('Input Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
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
  }

  Widget _buildIzinKeluarView(bool isDark) {
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
        heroTag: 'fab_santri_izin_keluar',
        backgroundColor: const Color(0xFF12B3B6),
        foregroundColor: Colors.black,
        onPressed: _showFormIzinKeluarModal,
        icon: const Icon(Icons.exit_to_app_rounded),
        label: const Text('Ajukan Izin Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyIzinKeluar,
        child: _isLoadingIzinKeluar
            ? const Center(child: CircularProgressIndicator())
            : _myIzinKeluarList.isEmpty
                ? Center(
                    child: Text('Belum ada riwayat izin keluar pondok.', style: TextStyle(color: onSurfaceVariant)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: _myIzinKeluarList.length,
                    itemBuilder: (context, idx) {
                      final iz = _myIzinKeluarList[idx];
                      final bool lewat23 = iz['is_lewat_jam_malam'] == true;
                      final String status = iz['status_approval'] ?? 'pending';
                      final String tanggal = _extractLocalDate(iz['tanggal']);
                      final String? kembaliAktual = iz['waktu_kembali_aktual'];
                      final String? buktiPath = iz['bukti_foto_webp'];

                      String statusLabel = 'MENUNGGU';
                      Color statusColor = secondaryGold;
                      if (status == 'approved') {
                        statusLabel = 'DISETUJUI';
                        statusColor = primaryCyan;
                      } else if (status == 'rejected') {
                        statusLabel = 'DITOLAK';
                        statusColor = const Color(0xFFFFB4AB);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: lewat23
                                ? const Color(0xFF93000A).withValues(alpha: 0.5)
                                : outlineColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(tanggal, style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                                  ],
                                ),
                                if (lewat23)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF93000A),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('LEWAT 23:00', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Keperluan: ${iz['keperluan']}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: secondaryGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Keluar: ${iz['waktu_keluar']} WITA • Estimasi: ${iz['estimasi_kembali']} WITA',
                                    style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            if (buktiPath != null && buktiPath.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => ExcelExporterHelper.showFullScreenImage(
                                  context,
                                  '${ApiClient.storageBaseUrl}$buktiPath',
                                  title: 'Foto Bukti Izin Keluar',
                                ),
                                icon: const Icon(Icons.zoom_in_rounded, size: 16),
                                label: const Text('Lihat Foto Bukti (Full Screen)', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                            const Divider(height: 20),
                            if (kembaliAktual != null)
                              Row(
                                children: [
                                  const Icon(Icons.verified, size: 16, color: primaryCyan),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sudah Kembali: ${_formatDateTimeWita(kembaliAktual)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryCyan),
                                  ),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF12B3B6),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _laporSudahKembali(iz['id']),
                                  icon: const Icon(Icons.location_on_outlined, size: 16),
                                  label: const Text('Lapor Sudah Kembali (Radius 100m)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
}