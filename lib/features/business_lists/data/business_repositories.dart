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

  Future<Map<String, dynamic>> get(int id) async =>
      CrudRepository(dio, errors).getObject('invoices/$id/');
  Future<Map<String, dynamic>> printData(
    int id, {
    int width = 80,
    String language = 'bilingual',
  }) async {
    try {
      final response = await dio.get<dynamic>(
        'invoices/$id/print-data/',
        queryParameters: {'paper_width': width, 'language': language},
      );
      return Map<String, dynamic>.from(ApiEnvelope.data(response.data) as Map);
    } catch (error) {
      throw errors.map(error);
    }
  }

  Future<List<int>> pdf(int id) async {
    try {
      final response = await dio.get<List<int>>(
        'invoices/$id/pdf/',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (error) {
      throw errors.map(error);
    }
  }
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

  Future<SaleSummary> create(
    SaleWriteRequest request,
    String idempotencyKey,
  ) async => SaleSummary.fromJson(
    await _postObject('sales/', request.toJson(), idempotencyKey),
  );
  Future<void> delete(int id) async {
    try {
      await dio.delete<dynamic>('sales/$id/');
    } catch (e) {
      throw errors.map(e);
    }
  }

  Future<List<TransactionOption>> searchClients(String query) =>
      _searchOptions('clients/', query, (j) => j['name']?.toString() ?? '');
  Future<List<TransactionOption>> searchProducts(String query) =>
      _searchProducts(dio, errors, query);
  Future<Map<String, dynamic>> price(
    int productId,
    int clientId, {
    int? packagingId,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        'products/$productId/price/',
        queryParameters: {'client_id': clientId, 'packaging_id': ?packagingId},
      );
      return Map<String, dynamic>.from(ApiEnvelope.data(response.data) as Map);
    } catch (e) {
      throw errors.map(e);
    }
  }

  Future<Map<String, dynamic>> _postObject(
    String path,
    Map<String, dynamic> data,
    String key,
  ) async {
    try {
      final r = await dio.post<dynamic>(
        path,
        data: data,
        options: Options(headers: {'Idempotency-Key': key}),
      );
      return ApiEnvelope.object(r.data);
    } catch (e) {
      throw errors.map(e);
    }
  }

  Future<List<TransactionOption>> _searchOptions(
    String path,
    String query,
    String Function(Map<String, dynamic>) label,
  ) async {
    try {
      final r = await dio.get<dynamic>(
        path,
        queryParameters: {'search': query, 'page_size': 20},
      );
      final d = ApiEnvelope.data(r.data);
      final raw = d is Map ? d['results'] : d;
      return (raw as List).map((e) {
        final j = Map<String, dynamic>.from(e as Map);
        return TransactionOption(
          id: (j['id'] as num).toInt(),
          label: label(j),
          meta: j,
        );
      }).toList();
    } catch (e) {
      throw errors.map(e);
    }
  }
}

class PurchasesRepository extends _BusinessRepository<PurchaseSummary> {
  const PurchasesRepository(Dio dio, ErrorMapper errors)
    : super(dio, errors, 'purchases/', PurchaseSummary.fromJson);
  Future<PurchaseSummary> create(
    PurchaseWriteRequest request,
    String key,
  ) async {
    try {
      final r = await dio.post<dynamic>(
        'purchases/',
        data: request.toJson(),
        options: Options(headers: {'Idempotency-Key': key}),
      );
      return PurchaseSummary.fromJson(ApiEnvelope.object(r.data));
    } catch (e) {
      throw errors.map(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await dio.delete<dynamic>('purchases/$id/');
    } catch (e) {
      throw errors.map(e);
    }
  }

  Future<List<TransactionOption>> searchSuppliers(String query) async {
    try {
      final r = await dio.get<dynamic>(
        'suppliers/',
        queryParameters: {'search': query, 'page_size': 20},
      );
      final d = ApiEnvelope.data(r.data);
      final raw = d is Map ? d['results'] : d;
      return (raw as List).map((e) {
        final j = Map<String, dynamic>.from(e as Map);
        return TransactionOption(
          id: (j['id'] as num).toInt(),
          label: j['name']?.toString() ?? '',
          meta: j,
        );
      }).toList();
    } catch (e) {
      throw errors.map(e);
    }
  }

  Future<List<TransactionOption>> searchProducts(String query) =>
      _searchProducts(dio, errors, query);
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
  Future<PaymentSummary> create(PaymentWriteRequest request, String key) async {
    try {
      final r = await dio.post<dynamic>(
        'payments/',
        data: request.toJson(),
        options: Options(headers: {'Idempotency-Key': key}),
      );
      return PaymentSummary.fromJson(ApiEnvelope.object(r.data));
    } catch (e) {
      throw errors.map(e);
    }
  }
}

Future<List<TransactionOption>> _searchProducts(
  Dio dio,
  ErrorMapper errors,
  String query,
) async {
  try {
    final response = await dio.get<dynamic>(
      'products/search/',
      queryParameters: {'q': query, 'context': 'loading_order'},
    );
    final data = ApiEnvelope.data(response.data);
    final raw = data is Map ? data['results'] : data;
    return (raw as List).map((e) {
      final j = Map<String, dynamic>.from(e as Map);
      return TransactionOption(
        id: (j['id'] as num).toInt(),
        label: j['name']?.toString() ?? '',
        meta: j,
      );
    }).toList();
  } catch (e) {
    throw errors.map(e);
  }
}
