import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AdNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AdNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _placeholder();
    }

    final image = CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(showLoader: true),
      errorWidget: (_, __, ___) => _placeholder(showError: true),
    );

    if (borderRadius == null) return image;

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder({bool showLoader = false, bool showError = false}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              showError ? Icons.broken_image : Icons.image,
              size: 40,
              color: Colors.grey[400],
            ),
    );
  }
}
