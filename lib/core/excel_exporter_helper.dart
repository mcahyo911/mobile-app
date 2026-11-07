import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';

class ExcelExporterHelper {
  /// Mengunduh / menyimpan file Excel (.csv UTF-8 BOM) langsung ke folder Download HP/PC
  static Future<void> downloadPresensiExcel({
    required BuildContext context,
    required String bulan,
    required String tahun,
    String? kategori,
  }) async {
    final apiClient = ApiClient();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyiapkan laporan Excel (.csv)...')),
      );

      final Map<String, dynamic> params = {
        'bulan': bulan,
        'tahun': tahun,
      };
      if (kategori != null && kategori.isNotEmpty) {
        params['kategori'] = kategori;
      }

      final res = await apiClient.dio.get(
        '/presensi/export-excel',
        queryParameters: params,
      );

      // Tambahkan UTF-8 BOM (\uFEFF) agar saat dibuka di Microsoft Excel HP/PC kolomnya langsung rapi
      final String rawCsv = res.data.toString();
      final String csvContent = rawCsv.startsWith('\uFEFF') ? rawCsv : '\uFEFF$rawCsv';

      final String katName =
          (kategori == null || kategori.isEmpty) ? 'Semua_Kategori' : kategori;
      final String baseName = 'Rekap_Presensi_${katName}_${bulan}_$tahun';

      final String queryStr = Uri(
        queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
      ).query;
      final String directDownloadUrl =
          '${ApiClient.baseUrl}/presensi/export-excel?$queryStr';

      if (kIsWeb) {
        if (!context.mounted) return;
        _showCsvPreviewDialog(context, '$baseName.csv', csvContent, directDownloadUrl);
        return;
      }

      File? savedFile;

      // 1. Jika di Android, arahkan langsung ke folder Download publik HP
      if (Platform.isAndroid) {
        final List<String> androidDownloadPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
        ];

        for (final path in androidDownloadPaths) {
          final d = Directory(path);
          if (await d.exists()) {
            try {
              savedFile = await _writeUniqueFile(d.path, baseName, csvContent);
              break;
            } catch (_) {
              // Lanjut coba path berikutnya jika ditolak OS
            }
          }
        }

        // Fallback ke folder eksternal aplikasi jika folder Download publik terkunci
        if (savedFile == null) {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            savedFile = await _writeUniqueFile(extDir.path, baseName, csvContent);
          }
        }
      }

      // 2. Jika di Linux / Windows / macOS, simpan ke folder Downloads PC
      if (savedFile == null &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        final dlDir = await getDownloadsDirectory();
        if (dlDir != null) {
          savedFile = await _writeUniqueFile(dlDir.path, baseName, csvContent);
        }
      }

      // 3. Fallback terakhir
      if (savedFile == null) {
        final docDir = await getApplicationDocumentsDirectory();
        savedFile = await _writeUniqueFile(docDir.path, baseName, csvContent);
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF1B5E20)),
              SizedBox(width: 8),
              Expanded(child: Text('Tersimpan di Download!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'File laporan berhasil diunduh. Silakan buka aplikasi File Manager > Folder Download di HP/Komputer Anda:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: SelectableText(
                  savedFile!.path,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showCsvPreviewDialog(
                  context,
                  savedFile!.path.split('/').last,
                  csvContent,
                  directDownloadUrl,
                );
              },
              child: const Text('Pratinjau Isi Tabel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ekspor Excel: ${ApiClient.getErrorMessage(e)}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Mencegah error Scoped Storage di Android 10+ saat menimpa file yang sudah ada di folder Download
  static Future<File> _writeUniqueFile(
    String dirPath,
    String baseName,
    String content,
  ) async {
    File file = File('$dirPath/$baseName.csv');
    int counter = 1;
    while (await file.exists()) {
      file = File('$dirPath/${baseName}_($counter).csv');
      counter++;
    }
    return await file.writeAsString(content, flush: true);
  }

  static void _showCsvPreviewDialog(
    BuildContext context,
    String fileName,
    String csvContent,
    String directUrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fileName, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 650,
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Isi Tabel CSV:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csvContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Menampilkan gambar dalam layar penuh (Full Screen) + fitur Cubit/Scroll Zoom (InteractiveViewer)
  static void showFullScreenImage(
    BuildContext context,
    String imageUrl, {
    String? title,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 72,
              child: Text(
                title ?? 'Pratinjau Gambar (Gunakan Scroll / Cubit untuk Zoom)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}