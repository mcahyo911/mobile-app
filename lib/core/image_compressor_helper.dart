import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PickedCompressedImage {
  final Uint8List bytes;
  final String filename;

  PickedCompressedImage({required this.bytes, required this.filename});
}

class ImageCompressorHelper {
  static final ImagePicker _picker = ImagePicker();
  static const int maxFileSizeInBytes = 500 * 1024; // 500 KB

  /// Mengambil 1 foto tunggal (bisa langsung Kamera atau 1 dari Galeri)
  static Future<PickedCompressedImage?> pickBytesUniversal({
    bool fromCamera = true,
  }) async {
    final bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final ImageSource effectiveSource =
        (fromCamera && isMobile) ? ImageSource.camera : ImageSource.gallery;

    final XFile? pickedFile = await _picker.pickImage(
      source: effectiveSource,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );

    if (pickedFile == null) return null;

    Uint8List rawBytes = await pickedFile.readAsBytes();

    if (isMobile) {
      try {
        final compressed = await FlutterImageCompress.compressWithList(
          rawBytes,
          minWidth: 1280,
          minHeight: 1280,
          quality: 80,
          format: CompressFormat.webp,
        );
        rawBytes = compressed;
      } catch (_) {}
    }

    return PickedCompressedImage(
      bytes: rawBytes,
      filename: 'kitab_${DateTime.now().millisecondsSinceEpoch}.webp',
    );
  }

  /// Mengambil banyak foto sekaligus (Multi-Select dari Galeri HP)
  static Future<List<PickedCompressedImage>> pickMultipleBytesUniversal() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );

    if (pickedFiles.isEmpty) return [];

    final bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    List<PickedCompressedImage> result = [];

    for (int i = 0; i < pickedFiles.length; i++) {
      Uint8List bytes = await pickedFiles[i].readAsBytes();

      if (isMobile) {
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1280,
            minHeight: 1280,
            quality: 80,
            format: CompressFormat.webp,
          );
          bytes = compressed;
        } catch (_) {}
      }

      result.add(
        PickedCompressedImage(
          bytes: bytes,
          filename: 'kitab_${DateTime.now().millisecondsSinceEpoch}_$i.webp',
        ),
      );
    }

    return result;
  }

  /// Method untuk Linux Desktop & Android/iOS yang mengembalikan File
  static Future<File?> pickAndCompressToWebp({bool fromCamera = true}) async {
    final bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final ImageSource effectiveSource =
        (fromCamera && isMobile) ? ImageSource.camera : ImageSource.gallery;

    final XFile? pickedFile = await _picker.pickImage(
      source: effectiveSource,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
    );

    if (pickedFile == null) return null;
    final File originalFile = File(pickedFile.path);

    if (!isMobile) return originalFile;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath =
          '${tempDir.path}/al_ajwah_${DateTime.now().millisecondsSinceEpoch}.webp';
      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        minWidth: 1280,
        minHeight: 1280,
        quality: 75,
        format: CompressFormat.webp,
      );
      return compressed != null ? File(compressed.path) : originalFile;
    } catch (_) {
      return originalFile;
    }
  }
}