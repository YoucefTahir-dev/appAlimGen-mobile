import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/thermal_paper.dart';

enum InvoicePaper { mm58, mm80, a4 }

class InvoicePaperSpec {
  const InvoicePaperSpec({
    required this.paper,
    required this.label,
    required this.widthMm,
    required this.dots,
    required this.charactersPerLine,
    required this.previewWidth,
  });

  final InvoicePaper paper;
  final String label;
  final int? widthMm;
  final int? dots;
  final int? charactersPerLine;
  final double previewWidth;

  bool get isThermal => paper != InvoicePaper.a4;

  static const mm58 = InvoicePaperSpec(
    paper: InvoicePaper.mm58,
    label: '58 mm',
    widthMm: 58,
    dots: ThermalPaperSpec.mm58Dots,
    charactersPerLine: ThermalPaperSpec.mm58Characters,
    previewWidth: 264,
  );
  static const mm80 = InvoicePaperSpec(
    paper: InvoicePaper.mm80,
    label: '80 mm',
    widthMm: 80,
    dots: ThermalPaperSpec.mm80Dots,
    charactersPerLine: ThermalPaperSpec.mm80Characters,
    previewWidth: 360,
  );
  static const a4 = InvoicePaperSpec(
    paper: InvoicePaper.a4,
    label: 'A4',
    widthMm: null,
    dots: null,
    charactersPerLine: null,
    previewWidth: 720,
  );

  static InvoicePaperSpec of(InvoicePaper paper) => switch (paper) {
    InvoicePaper.mm58 => mm58,
    InvoicePaper.mm80 => mm80,
    InvoicePaper.a4 => a4,
  };

  static InvoicePaper fromPrinterWidth(int? width) =>
      width == 58 ? InvoicePaper.mm58 : InvoicePaper.mm80;
}

class InvoiceDocumentData {
  const InvoiceDocumentData({required this.sale});

  final SaleDetails sale;

  String get number => sale.number;
  String get ticketNumber => sale.ticketNumber;
  String get issuedAt => sale.date;
  SaleClientDetails get client => sale.client;
  List<SaleLineDetails> get lines => sale.lines;
  String get subtotal => sale.subtotal;
  String get discount => sale.discount;
  String get taxRate => sale.taxRate;
  String get taxAmount => sale.taxAmount;
  String get total => sale.total;
  String get amountPaid => sale.amountPaid;
  String get balanceDue => sale.balanceDue;
  String get paymentType => sale.paymentType;
  String get paymentStatus => sale.paymentStatus;
}
