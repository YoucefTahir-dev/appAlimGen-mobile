import 'dart:async';

import 'package:app_alim_gen_mobile/core/config/app_config.dart';
import 'package:flutter/painting.dart';

/// Loads only the logo referenced by the invoice's company snapshot. This is
/// deliberately independent of the authenticated API client: media URLs must
/// never receive its bearer token, including when hosted on another origin.
class InvoiceLogoLoader {
  const InvoiceLogoLoader();

  ImageProvider<Object> imageProvider(Uri uri) => ResizeImage(
    NetworkImage(uri.toString()),
    width: 256,
    height: 256,
    policy: ResizeImagePolicy.fit,
  );

  Future<ImageInfo?> load(String? value) async {
    final source = value?.trim() ?? '';
    if (source.isEmpty) return null;
    final parsed = Uri.tryParse(source);
    if (parsed == null) return null;
    final uri = AppConfig.apiBaseUri.resolveUri(parsed);
    if (uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' && AppConfig.isLocalDevelopment(uri)))) {
      return null;
    }

    final result = Completer<ImageInfo?>();
    final stream = imageProvider(uri).resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (image, _) {
        if (!result.isCompleted) {
          result.complete(image);
        } else {
          image.dispose();
        }
      },
      onError: (Object error, StackTrace? stack) {
        if (!result.isCompleted) result.complete(null);
      },
    );
    stream.addListener(listener);
    try {
      // An unavailable media asset must not prevent printing the invoice.
      return await result.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (!result.isCompleted) result.complete(null);
          return null;
        },
      );
    } finally {
      stream.removeListener(listener);
    }
  }
}
