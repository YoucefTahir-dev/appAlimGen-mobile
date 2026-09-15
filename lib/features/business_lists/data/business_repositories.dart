import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/network/crud_repository.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
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

  CrudRepository get _crud => CrudRepository(dio, errors);
  Future<SupplierDetails> get(int id) async =>
      SupplierDetails.fromJson(await _crud.getObject('suppliers/$id/'));
  Future<SupplierDetails> create(SupplierWriteRequest request) async =>
      SupplierDetails.fromJson(
        await _crud.create('suppliers/', request.toJson()),
      );
  Future<SupplierDetails> update(int id, SupplierWriteRequest request) async =>
      SupplierDetails.fromJson(
        await _crud.patch('suppliers/$id/', request.toJson()),
      );
  Future<void> delete(int id) => _crud.delete('suppliers/$id/');
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

  CrudRepository get _crud => CrudRepository(dio, errors);
  Future<ExpenseDetails> get(int id) async =>
      ExpenseDetails.fromJson(await _crud.getObject('expenses/$id/'));
  Future<ExpenseDetails> create(ExpenseWriteRequest request) async =>
      ExpenseDetails.fromJson(
        await _crud.create('expenses/', request.toJson()),
      );
  Future<ExpenseDetails> update(int id, ExpenseWriteRequest request) async =>
      ExpenseDetails.fromJson(
        await _crud.patch('expenses/$id/', request.toJson()),
      );
  Future<void> delete(int id) => _crud.delete('expenses/$id/');
  Future<List<BusinessOption>> options(String path) async {
    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: {'page_size': 100},
      );
      final data = ApiEnvelope.data(response.data);
      final raw = data is Map ? data['results'] : data;
      if (raw is! List) throw const FormatException('Liste invalide.');
      return raw
          .map(
            (item) =>
                BusinessOption.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } catch (error) {
      throw errors.map(error);
    }
  }
}

class PaymentsRepository extends _BusinessRepository<PaymentSummary> {
  const PaymentsRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'payments/', PaymentSummary.fromJson);
}
