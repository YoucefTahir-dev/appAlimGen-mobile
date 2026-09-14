import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:dio/dio.dart';

Future<PageData<T>> loadApiPage<T>({
  required Dio dio,
  required ErrorMapper errors,
  required String path,
  required int page,
  required String query,
  required T Function(Map<String, dynamic>) decode,
  CancelToken? cancelToken,
}) async {
  try {
    final response = await dio.get<dynamic>(
      path,
      cancelToken: cancelToken,
      queryParameters: {
        'page': page,
        'page_size': 25,
        if (query.isNotEmpty) 'search': query,
      },
    );
    return PageData.fromApi(ApiEnvelope.data(response.data), decode);
  } catch (error) {
    throw errors.map(error);
  }
}
