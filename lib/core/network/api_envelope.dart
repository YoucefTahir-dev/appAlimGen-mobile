class ApiEnvelope {
  ApiEnvelope._();
  static dynamic data(dynamic body) {
    if (body is! Map || body['success'] != true || !body.containsKey('data')) {
      throw const FormatException('Réponse API invalide.');
    }
    return body['data'];
  }

  static Map<String, dynamic> object(dynamic body) {
    final value = data(body);
    if (value is! Map) {
      throw const FormatException('Objet API invalide.');
    }
    return Map<String, dynamic>.from(value);
  }
}
