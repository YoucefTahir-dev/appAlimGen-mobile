import 'dart:io';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  final int invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  late Future<Map<String, dynamic>> _invoice;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _invoice = ref.read(invoicesRepositoryProvider).get(widget.invoiceId);
  }

  String _message(Object error) =>
      error is AppFailure ? error.message : error.toString();

  Future<void> _openPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(invoicesRepositoryProvider)
          .pdf(widget.invoiceId);
      if (bytes.isEmpty) throw StateError('Le PDF reçu est vide.');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/facture_${widget.invoiceId}.pdf');
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
    setState(() => _busy = true);
    try {
      final repository = ref.read(printersRepositoryProvider);
      final defaultSummary = await repository.getDefault();
      if (defaultSummary == null) {
        throw StateError('Aucune imprimante active définie par défaut.');
      }
      final printer = await repository.get(defaultSummary.id);
      if (printer.connectionMode != 'bluetooth') {
        throw StateError(
          "L'impression Android locale nécessite une imprimante Bluetooth.",
        );
      }
      final data = await ref
          .read(invoicesRepositoryProvider)
          .printData(
            widget.invoiceId,
            width: printer.paperWidth,
            language: 'fr',
          );
      final service = ref.read(printerTestServiceProvider);
      final bytes = service.driver.invoiceTicket(
        data: data,
        paperWidth: printer.paperWidth,
      );
      await service.send(printer: printer, bytes: bytes);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Données envoyées'),
          content: const Text(
            "La facture a été envoyée à l'imprimante. Vérifiez le papier : "
            "l'envoi logiciel ne confirme pas l'impression physique.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showError(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final canPdf = user?.can(AppPermissions.downloadInvoicePdf) ?? false;
    final canPrint = user?.can(AppPermissions.printInvoice) ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail facture')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _invoice,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_message(snapshot.error!)),
                    FilledButton(
                      onPressed: () => setState(
                        () => _invoice = ref
                            .read(invoicesRepositoryProvider)
                            .get(widget.invoiceId),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!;
          final lines =
              (data['lines'] as List? ?? data['items'] as List? ?? const []);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data['invoice_number']?.toString() ??
                    data['ticket_number']?.toString() ??
                    'Facture #${widget.invoiceId}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Date : ${data['created_at'] ?? '-'}'),
              Text('Statut : ${data['payment_status'] ?? '-'}'),
              Text('Total : ${data['total'] ?? '0.00'} DZD'),
              const Divider(height: 32),
              Text('Produits', style: Theme.of(context).textTheme.titleLarge),
              for (final raw in lines.whereType<Map>())
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    raw['product_name']?.toString() ??
                        raw['name']?.toString() ??
                        'Produit #${raw['product'] ?? raw['product_id'] ?? '-'}',
                  ),
                  subtitle: Text('Quantité : ${raw['quantity'] ?? '-'}'),
                  trailing: Text(
                    '${raw['total'] ?? raw['line_total'] ?? raw['unit_price'] ?? '-'} DZD',
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (canPdf)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _openPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Ouvrir le PDF'),
                    ),
                  if (canPrint)
                    FilledButton.icon(
                      onPressed: _busy ? null : _print,
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Imprimer'),
                    ),
                  if (_busy) const CircularProgressIndicator(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
