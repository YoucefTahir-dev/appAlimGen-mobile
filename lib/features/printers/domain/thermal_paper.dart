class ThermalPaperSpec {
  const ThermalPaperSpec({
    required this.widthMm,
    required this.dots,
    required this.charactersPerLine,
  });

  final int widthMm;
  final int dots;
  final int charactersPerLine;

  static const mm58Dots = 384;
  static const mm58Characters = 32;
  static const mm80Dots = 576;
  static const mm80Characters = 48;

  static const mm58 = ThermalPaperSpec(
    widthMm: 58,
    dots: mm58Dots,
    charactersPerLine: mm58Characters,
  );
  static const mm80 = ThermalPaperSpec(
    widthMm: 80,
    dots: mm80Dots,
    charactersPerLine: mm80Characters,
  );

  static ThermalPaperSpec fromWidth(int width) => width == 58 ? mm58 : mm80;
}
