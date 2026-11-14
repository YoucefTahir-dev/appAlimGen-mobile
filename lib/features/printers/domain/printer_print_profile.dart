/// Device-local tuning, not a claim about the printer's receive-buffer size.
/// Defaults retain the existing 1024-byte / 5 ms and 128-row compatibility path.
class PrinterPrintProfile {
  const PrinterPrintProfile({
    this.chunkBytes = 1024,
    this.pauseMs = 5,
    this.rasterBandRows = 128,
    this.feedLines = 3,
    this.cutPaper = true,
  });

  final int chunkBytes, pauseMs, rasterBandRows, feedLines;
  final bool cutPaper;

  void validate() {
    if (chunkBytes < 64 ||
        chunkBytes > 4096 ||
        pauseMs < 0 ||
        pauseMs > 1000 ||
        rasterBandRows < 1 ||
        rasterBandRows > 256 ||
        feedLines < 1 ||
        feedLines > 10) {
      throw ArgumentError('Profil d’impression local invalide.');
    }
  }

  factory PrinterPrintProfile.fromJson(Map<String, dynamic> json) {
    final profile = PrinterPrintProfile(
      chunkBytes: (json['chunk_bytes'] as num?)?.toInt() ?? 1024,
      pauseMs: (json['pause_ms'] as num?)?.toInt() ?? 5,
      rasterBandRows: (json['raster_band_rows'] as num?)?.toInt() ?? 128,
      feedLines: (json['feed_lines'] as num?)?.toInt() ?? 3,
      cutPaper: json['cut_paper'] != false,
    );
    profile.validate();
    return profile;
  }

  Map<String, dynamic> toJson() => {
    'chunk_bytes': chunkBytes,
    'pause_ms': pauseMs,
    'raster_band_rows': rasterBandRows,
    'feed_lines': feedLines,
    'cut_paper': cutPaper,
  };
}
