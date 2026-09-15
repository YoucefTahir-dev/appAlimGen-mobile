import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:dio/dio.dart';

class CrudRepository {
  const CrudRepository(this.dio, this.errors);

  final Dio dio;
  final ErrorMapper errors;

  Future<Map<String, dynamic>> getObject(String path) =>
      _object(() => dio.get<dynamic>(path));

  Future<Map<String, dynamic>> create(String path, Map<String, dynamic> data) =>
      _object(() => dio.post<dynamic>(path, data: data));

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) =>
      _object(() => dio.patch<dynamic>(path, data: data));

  Future<void> delete(String path) async {
    try {
      await dio.delete<dynamic>(path);
    } catch (error) {
      throw errors.map(error);
    }
  }

  Future<Map<String, dynamic>> _object(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return ApiEnvelope.object(response.data);
    } catch (error) {
      throw errors.map(error);
    }
  }
}
