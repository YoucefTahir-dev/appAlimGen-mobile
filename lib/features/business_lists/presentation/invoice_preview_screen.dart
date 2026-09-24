import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_document_view.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.sale,
    required this.canPrint,
    required this.canViewPdf,
    this.initialPrinter,
    this.initialPaper,
    this.autoPrint = false,
  });

  final SaleDetails sale;
  final bool canPrint;
  final bool canViewPdf;
  final PrinterDetails? initialPrinter;
  final InvoicePaper? initialPaper;
  final bool autoPrint;

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  final _documentKey = GlobalKey();
  InvoicePaper _paper = InvoicePaper.mm80;
  PrinterDetails? _printer;
  bool _busy = false;
  bool _autoPrintStarted = false;

  @override
  void initState() {
    super.initState();
    _printer = widget.initialPrinter;
    _paper = widget.initialPaper ?? _paper;
    if (_printer != null) {
      if (widget.initialPaper == null) {
        _paper = InvoicePaperSpec.fromPrinterWidth(_printer!.paperWidth);
      }
      _scheduleAutoPrint();
    } else if (widget.canPrint) {
      Future.microtask(_loadDefaultPrinter);
    } else {
      _scheduleAutoPrint();
    }
  }

  void _scheduleAutoPrint() {
    if (!widget.autoPrint || _autoPrintStarted) return;
    _autoPrintStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _print();
    });
  }

  Future<void> _loadDefaultPrinter() async {
    try {
      final repository = ref.read(printersRepositoryProvider);
      final summary = await repository.getDefault();
      if (summary == null) {
        _scheduleAutoPrint();
        return;
      }
      final printer = await repository.get(summary.id);
      if (!mounted) return;
      setState(() {
        _printer = printer;
        if (widget.initialPaper == null) {
          _paper = InvoicePaperSpec.fromPrinterWidth(printer.paperWidth);
        }
      });
      _scheduleAutoPrint();
    } catch (_) {
      // The preview remains available even if printer discovery is unavailable.
      _scheduleAutoPrint();
    }
  }

  String _message(Object error) =>
      error is AppFailure ? error.message : error.toString();

  bool get _containsArabic {
    final values = <String>[
      widget.sale.client.name,
      widget.sale.client.address,
      ...widget.sale.lines.map((line) => line.productName),
      ...widget.sale.lines.map((line) => line.packagingName),
    ];
    return RegExp(r'[\u0600-\u06ff]').hasMatch(values.join(' '));
  }

  Future<Uint8List> _rasterBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _documentKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Aperçu indisponible.');
    final spec = InvoicePaperSpec.of(_paper);
    final image = await boundary.toImage(
      pixelRatio: spec.dots! / boundary.size.width,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError('Conversion raster impossible.');
      return ref
          .read(printerTestServiceProvider)
          .driver
          .rasterTicket(
            rgba: data.buffer.asUint8List(),
            width: image.width,
            height: image.height,
          );
    } finally {
      image.dispose();
    }
  }

  Future<PrinterDetails?> _requirePrinter() async {
    if (_printer != null) return _printer;
    final repository = ref.read(printersRepositoryProvider);
    final summary = await repository.getDefault();
    if (summary != null) {
      final printer = await repository.get(summary.id);
      if (mounted) setState(() => _printer = printer);
      return printer;
    }
    if (!mounted) return null;
    final configure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(SalesStrings.of(context)('noPrinter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(SalesStrings.of(context)('later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(SalesStrings.of(context)('configurePrinter')),
          ),
        ],
      ),
    );
    if (configure == true && mounted) context.push('/printers');
    return null;
  }

  Future<void> _openPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(invoicesRepositoryProvider)
          .pdf(widget.sale.id);
      if (bytes.isEmpty) throw StateError('Le PDF reçu est vide.');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/facture_${widget.sale.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await const MethodChannel(
        'com.elamine.erp/files',
      ).invokeMethod<void>('openPdf', {'path': file.path});
    } catch (error) {
      if (mounted) _showError(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    if (_paper == InvoicePaper.a4) return _openPdf();
    final languageCode = ref.read(localeProvider).languageCode;
    setState(() => _busy = true);
    try {
      final printer = await _requirePrinter();
      if (printer == null) return;
      if (printer.connectionMode != 'bluetooth') {
        throw StateError(
          "L'impression Android locale nécessite une imprimante Bluetooth.",
        );
      }
      final width = InvoicePaperSpec.of(_paper).widthMm!;
      final bytes = _containsArabic || languageCode == 'ar'
          ? await _rasterBytes()
          : ref
                .read(printerTestServiceProvider)
                .driver
                .invoiceTicket(
                  data: await ref
                      .read(invoicesRepositoryProvider)
                      .printData(
                        widget.sale.id,
                        width: width,
                        language: languageCode,
                      ),
                  paperWidth: width,
                );
      await ref
          .read(printerTestServiceProvider)
          .send(printer: printer, bytes: bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SalesStrings.of(context)('sentToPrinter'))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(SalesStrings.of(context)('printFailed')),
          content: Text(
            "${SalesStrings.of(context)('salePreserved')}\n\n${_message(error)}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(SalesStrings.of(context)('later')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(SalesStrings.of(context)('retry')),
            ),
          ],
        ),
      );
      if (retry == true && mounted) {
        setState(() => _busy = false);
        return _print();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    final spec = InvoicePaperSpec.of(_paper);
    final data = InvoiceDocumentData(sale: widget.sale);
    return Scaffold(
      appBar: AppBar(title: Text(t('invoicePreview'))),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('printFormat'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 7),
                  SegmentedButton<InvoicePaper>(
                    key: const Key('invoice-format-selector'),
                    segments: const [
                      ButtonSegment(
                        value: InvoicePaper.mm58,
                        label: Text('58 mm'),
                      ),
                      ButtonSegment(
                        value: InvoicePaper.mm80,
                        label: Text('80 mm'),
                      ),
                      ButtonSegment(value: InvoicePaper.a4, label: Text('A4')),
                    ],
                    selected: {_paper},
                    onSelectionChanged: (selection) =>
                        setState(() => _paper = selection.first),
                  ),
                  if (_printer != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${t('defaultPrinter')} : ${_printer!.name} · ${_printer!.paperWidth} mm',
                      key: const Key('default-printer-label'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xffeceff1),
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      constrained: false,
                      minScale: .55,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: RepaintBoundary(
                          key: _documentKey,
                          child: InvoiceDocumentView(data: data, paper: _paper),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    start: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          '${t('documentPreview')} · ${spec.label}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_paper == InvoicePaper.a4 && widget.canViewPdf)
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('preview-pdf-action'),
                  onPressed: _busy ? null : _openPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(t('viewPdf')),
                ),
              ),
            if (_paper == InvoicePaper.a4 && widget.canViewPdf)
              const SizedBox(width: 10),
            if (widget.canPrint ||
                (_paper == InvoicePaper.a4 && widget.canViewPdf))
              Expanded(
                child: FilledButton.icon(
                  key: const Key('preview-print-action'),
                  onPressed: _busy ? null : _print,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined),
                  label: Text(
                    _paper == InvoicePaper.a4
                        ? t('openPdfToPrint')
                        : t('print'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
