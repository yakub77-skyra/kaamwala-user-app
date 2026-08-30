/// Reusable image-picking utilities with validation + compression.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kaamwala/core/theme/app_theme.dart';

/// Result of picking an image: compressed bytes + original file type.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.originalName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String originalName;
  final String mimeType;
}

/// Errors that can occur while picking/validating an image.
class ImagePickError implements Exception {
  const ImagePickError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Max allowed image size after compression (512 KB - keeps uploads fast).
const int kMaxImageBytes = 512 * 1024;

/// Allowed image MIME prefixes.
const List<String> _allowedPrefixes = ['image/'];

/// Picks a single image (camera or gallery), validates it, and compresses it.
/// Throws [ImagePickError] on validation failure.
class KwImagePicker {
  KwImagePicker._();

  static final KwImagePicker instance = KwImagePicker._();
  final ImagePicker _picker = ImagePicker();

  /// Pick a single image from [source]. Throws [ImagePickError] if the user
  /// cancels or the file is invalid/too large after compression.
  Future<PickedImage> pickSingle(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (x == null) {
      throw const ImagePickError('No image selected');
    }
    final mimeType = _mimeType(x.name);
    if (!_allowedPrefixes.any(mimeType.startsWith)) {
      throw const ImagePickError('Please select an image file (jpg, png)');
    }
    final bytes = await x.readAsBytes();
    return _compress(bytes, x.name, mimeType);
  }

  /// Pick multiple images from the gallery. Returns only the valid, compressed
  /// ones (up to [maxCount]); invalid/oversized files are skipped silently.
  Future<List<PickedImage>> pickMulti({required int maxCount}) async {
    final xs = await _picker.pickMultiImage(imageQuality: 82);
    if (xs.isEmpty) {
      throw const ImagePickError('No images selected');
    }
    final List<PickedImage> out = [];
    for (final x in xs.take(maxCount)) {
      final mimeType = _mimeType(x.name);
      if (!_allowedPrefixes.any(mimeType.startsWith)) continue;
      final bytes = await x.readAsBytes();
      try {
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          quality: 70,
          minWidth: 720,
          minHeight: 720,
        );
        if (compressed.length > kMaxImageBytes) continue;
        out.add(
          PickedImage(
            bytes: compressed,
            originalName: x.name,
            mimeType: mimeType,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    if (out.isEmpty) {
      throw const ImagePickError('Selected images were too large or invalid');
    }
    return out;
  }

  Future<PickedImage> _compress(
    Uint8List bytes,
    String originalName,
    String mimeType,
  ) async {
    var compressed = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 80,
      minWidth: 1080,
      minHeight: 1080,
    );
    if (compressed.length > kMaxImageBytes) {
      var q = 60;
      while (compressed.length > kMaxImageBytes && q >= 30) {
        compressed = await FlutterImageCompress.compressWithList(
          bytes,
          quality: q,
          minWidth: 800,
          minHeight: 800,
        );
        q -= 10;
      }
      if (compressed.length > kMaxImageBytes) {
        throw const ImagePickError('Image is too large');
      }
    }
    return PickedImage(
      bytes: compressed,
      originalName: originalName,
      mimeType: mimeType,
    );
  }

  static String _mimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/$ext';
    }
  }
}

/// A square thumbnail for a picked image with a remove affordance.
class KwImageThumb extends StatelessWidget {
  const KwImageThumb({
    super.key,
    required this.bytes,
    required this.onRemove,
    this.size = 72,
  });

  final Uint8List bytes;
  final VoidCallback onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(KwRadius.md),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: KwColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: KwColors.surface, width: 1.5),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tile showing a full-width image preview with a remove button.
class KwImagePreview extends StatelessWidget {
  const KwImagePreview({
    super.key,
    required this.bytes,
    required this.onRemove,
    required this.label,
  });

  final Uint8List bytes;
  final VoidCallback onRemove;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KwRadius.md),
              child: Image.memory(
                bytes,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(KwRadius.pill),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: KwColors.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: KwColors.line, width: 1),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KwSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: KwColors.muted),
        ),
      ],
    );
  }
}

/// A row of small thumbnails for multi-image selection (work photos).
class KwImageThumbRow extends StatelessWidget {
  const KwImageThumbRow({
    super.key,
    required this.images,
    required this.onRemove,
  });

  final List<Uint8List> images;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: KwSpacing.sm,
      runSpacing: KwSpacing.sm,
      children: [
        for (var i = 0; i < images.length; i++)
          KwImageThumb(bytes: images[i], size: 72, onRemove: () => onRemove(i)),
      ],
    );
  }
}
