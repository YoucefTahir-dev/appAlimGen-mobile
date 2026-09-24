import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:flutter/material.dart';

class InvoiceDocumentView extends StatelessWidget {
  const InvoiceDocumentView({
    super.key,
    required this.data,
    required this.paper,
  });

  final InvoiceDocumentData data;
  final InvoicePaper paper;

  @override
  Widget build(BuildContext context) {
    final spec = InvoicePaperSpec.of(paper);
    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      alignment: Alignment.topCenter,
      child: Container(
        key: Key('invoice-paper-${paper.name}'),
        width: spec.previewWidth,
        constraints: BoxConstraints(
          minHeight: paper == InvoicePaper.a4 ? spec.previewWidth * 1.414 : 0,
        ),
        padding: EdgeInsets.all(switch (paper) {
          InvoicePaper.mm58 => 14,
          InvoicePaper.mm80 => 20,
          InvoicePaper.a4 => 42,
        }),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(paper == InvoicePaper.a4 ? 2 : 5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: Colors.black,
            fontSize: paper == InvoicePaper.mm58 ? 10 : 12,
            height: 1.28,
          ),
          child: paper == InvoicePaper.a4
              ? _A4Invoice(data: data)
              : _ThermalInvoice(data: data, paper: paper),
        ),
      ),
    );
  }
}

class _ThermalInvoice extends StatelessWidget {
  const _ThermalInvoice({required this.data, required this.paper});

  final InvoiceDocumentData data;
  final InvoicePaper paper;

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    final compact = paper == InvoicePaper.mm58;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: compact ? 42 : 58,
            height: compact ? 42 : 58,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t('companyName'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 14 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          t('companyNameAr'),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const _ReceiptRule(),
        Text(
          '${t('invoice')}\n${data.number}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(_displayDate(data.issuedAt), textAlign: TextAlign.center),
        const SizedBox(height: 5),
        _LabelValue(
          label: t('client'),
          value: data.client.name,
          compact: compact,
        ),
        if (data.client.phone.isNotEmpty)
          _LabelValue(
            label: t('phone'),
            value: data.client.phone,
            compact: compact,
          ),
        const _ReceiptRule(),
        if (compact)
          for (final line in data.lines) ...[
            Text(
              line.productName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            _LabelValue(
              label: '${line.quantity} × ${line.unitPrice}',
              value: line.total,
              compact: true,
            ),
            if (line.packagingName.isNotEmpty)
              Text(line.packagingName, style: const TextStyle(fontSize: 9)),
            const SizedBox(height: 3),
          ]
        else
          _ThermalItemsTable(data: data),
        const _ReceiptRule(),
        _LabelValue(
          label: t('subtotal'),
          value: '${data.subtotal} DZD',
          compact: compact,
        ),
        _LabelValue(
          label: t('discount'),
          value: '${data.discount} DZD',
          compact: compact,
        ),
        _LabelValue(
          label: '${t('tax')} (${data.taxRate}%)',
          value: '${data.taxAmount} DZD',
          compact: compact,
        ),
        const SizedBox(height: 3),
        _LabelValue(
          label: t('totalTtc').toUpperCase(),
          value: '${data.total} DZD',
          compact: compact,
          strong: true,
        ),
        _LabelValue(
          label: t('paidShort'),
          value: '${data.amountPaid} DZD',
          compact: compact,
        ),
        _LabelValue(
          label: t('dueShort'),
          value: '${data.balanceDue} DZD',
          compact: compact,
          strong: true,
        ),
        _LabelValue(
          label: t('paymentMethod'),
          value: data.paymentType,
          compact: compact,
        ),
        const _ReceiptRule(),
        Text(
          t('thankYou'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ThermalItemsTable extends StatelessWidget {
  const _ThermalItemsTable({required this.data});
  final InvoiceDocumentData data;

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.7),
        1: FlexColumnWidth(.7),
        2: FlexColumnWidth(1.1),
        3: FlexColumnWidth(1.25),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black54)),
          ),
          children: [
            _Cell(t('article'), strong: true),
            _Cell(t('quantity'), strong: true, numeric: true),
            _Cell('PU', strong: true, numeric: true),
            _Cell(t('total'), strong: true, numeric: true),
          ],
        ),
        for (final line in data.lines)
          TableRow(
            children: [
              _Cell(
                line.packagingName.isEmpty
                    ? line.productName
                    : '${line.productName}\n${line.packagingName}',
              ),
              _Cell('${line.quantity}', numeric: true),
              _Cell(line.unitPrice, numeric: true),
              _Cell(line.total, numeric: true),
            ],
          ),
      ],
    );
  }
}

class _A4Invoice extends StatelessWidget {
  const _A4Invoice({required this.data});
  final InvoiceDocumentData data;

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/logo.png', width: 82, height: 82),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('companyName'),
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  Text(
                    t('companyNameAr'),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t('invoice').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  data.number,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(_displayDate(data.issuedAt)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xfff3f6f5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('client').toUpperCase(),
                style: TextStyle(color: primary, fontWeight: FontWeight.w700),
              ),
              Text(
                data.client.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (data.client.address.isNotEmpty)
                Text('${t('address')} : ${data.client.address}'),
              if (data.client.phone.isNotEmpty)
                Text('${t('phone')} : ${data.client.phone}'),
              if (data.client.customerType.isNotEmpty)
                Text(data.client.customerType),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3.2),
            1: FlexColumnWidth(1.3),
            2: FlexColumnWidth(.8),
            3: FlexColumnWidth(1.25),
            4: FlexColumnWidth(1.35),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: primary),
              children: [
                _Cell(t('article'), strong: true, inverse: true),
                _Cell(t('packaging'), strong: true, inverse: true),
                _Cell(
                  t('quantity'),
                  strong: true,
                  inverse: true,
                  numeric: true,
                ),
                _Cell(
                  t('unitPrice'),
                  strong: true,
                  inverse: true,
                  numeric: true,
                ),
                _Cell(t('total'), strong: true, inverse: true, numeric: true),
              ],
            ),
            for (var index = 0; index < data.lines.length; index++)
              TableRow(
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.white : const Color(0xfff7f7f7),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xffdddddd)),
                  ),
                ),
                children: [
                  _Cell(data.lines[index].productName),
                  _Cell(data.lines[index].packagingName),
                  _Cell('${data.lines[index].quantity}', numeric: true),
                  _Cell(data.lines[index].unitPrice, numeric: true),
                  _Cell(data.lines[index].total, numeric: true),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 310,
            child: Column(
              children: [
                _LabelValue(
                  label: t('subtotal'),
                  value: '${data.subtotal} DZD',
                ),
                _LabelValue(
                  label: t('discount'),
                  value: '${data.discount} DZD',
                ),
                _LabelValue(
                  label: '${t('tax')} (${data.taxRate}%)',
                  value: '${data.taxAmount} DZD',
                ),
                const Divider(),
                _LabelValue(
                  label: t('totalTtc'),
                  value: '${data.total} DZD',
                  strong: true,
                ),
                _LabelValue(label: t('paid'), value: '${data.amountPaid} DZD'),
                _LabelValue(
                  label: t('due'),
                  value: '${data.balanceDue} DZD',
                  strong: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 54),
        const Divider(),
        Text(
          t('thankYou'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ReceiptRule extends StatelessWidget {
  const _ReceiptRule();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 7),
    child: Divider(height: 1, thickness: 1, color: Colors.black54),
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.compact = false,
    this.strong = false,
  });
  final String label, value;
  final bool compact, strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: strong ? const TextStyle(fontWeight: FontWeight.w800) : null,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              fontSize: compact ? 10 : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    this.strong = false,
    this.numeric = false,
    this.inverse = false,
  });
  final String text;
  final bool strong, numeric, inverse;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    child: Text(
      text,
      textAlign: numeric ? TextAlign.end : TextAlign.start,
      overflow: TextOverflow.visible,
      style: TextStyle(
        color: inverse ? Colors.white : Colors.black,
        fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
        fontSize: 10,
      ),
    ),
  );
}

String _displayDate(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
}
