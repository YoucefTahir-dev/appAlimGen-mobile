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
  SaleCompanyDetails get company => sale.company;
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
  bool get showTicketInformation => sale.showLegalInformation;

  /// Both preview and print consume the same server-valued snapshot in the
  /// same list order. A second API response must not reorder or refresh it.
  Map<String, dynamic> toTicketPayload() => {
    if (showTicketInformation) ...{
      'invoice_number': number,
      'ticket_number': ticketNumber,
      'issued_at': issuedAt,
    },
    'show_ticket_information': showTicketInformation,
    'show_legal_information': showTicketInformation,
    'company': {
      'name_fr': company.name,
      'logo_url': company.logoUrl,
      if (showTicketInformation) ...{
        'address': company.address,
        'phone': company.phone,
        'tax_number': company.taxNumber,
        'nis': company.nis,
        'rc_number': company.rcNumber,
        'article_number': company.articleNumber,
      },
    },
    if (showTicketInformation)
      'customer': {
        'name': client.name,
        'phone': client.phone,
        'address': client.address,
        'tax_number': client.taxNumber,
        'nis': client.nis,
        'trade_register_number': client.tradeRegisterNumber,
        'article_number': client.articleNumber,
      },
    'items': [
      for (final line in lines)
        {
          'name': line.productName,
          'quantity': line.quantity,
          'packaging': line.packagingName,
          'unit_price': line.unitPrice,
          'total': line.total,
        },
    ],
    'totals': {
      'total_ttc': total,
      if (showTicketInformation) ...{
        'total_ht': subtotal,
        'discount': discount,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
        'amount_paid': amountPaid,
        'balance_due': balanceDue,
        'payment_method': paymentType,
      },
    },
  };
}
