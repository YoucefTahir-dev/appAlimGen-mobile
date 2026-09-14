import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:dio/dio.dart';

abstract class _BusinessRepository<T> {
  const _BusinessRepository(this.dio, this.errors, this.path, this.decode);
  final Dio dio;
  final ErrorMapper errors;
  final String path;
  final T Function(Map<String, dynamic>) decode;
  Future<PageData<T>> fetch({required int page, String query = ''}) =>
      loadApiPage(
        dio: dio,
        errors: errors,
        path: path,
        page: page,
        query: query,
        decode: decode,
      );
}

class InvoicesRepository extends _BusinessRepository<InvoiceSummary> {
  const InvoicesRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'invoices/', InvoiceSummary.fromJson);
}

class SuppliersRepository extends _BusinessRepository<SupplierSummary> {
  const SuppliersRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'suppliers/', SupplierSummary.fromJson);
}

class SalesRepository extends _BusinessRepository<SaleSummary> {
  const SalesRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'sales/', SaleSummary.fromJson);
}

class PurchasesRepository extends _BusinessRepository<PurchaseSummary> {
  const PurchasesRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'purchases/', PurchaseSummary.fromJson);
}

class ExpensesRepository extends _BusinessRepository<ExpenseSummary> {
  const ExpensesRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'expenses/', ExpenseSummary.fromJson);
}

class PaymentsRepository extends _BusinessRepository<PaymentSummary> {
  const PaymentsRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'payments/', PaymentSummary.fromJson);
}
