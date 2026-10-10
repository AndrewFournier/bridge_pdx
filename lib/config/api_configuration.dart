import 'package:flutter/foundation.dart';

class ApiConfiguration {
  ApiConfiguration({Uri? baseUri}) : baseUri = baseUri ?? developmentBaseUri();

  static const _definedBaseUrl = String.fromEnvironment(
    'BRIDGE_PDX_API_BASE_URL',
  );

  final Uri baseUri;

  static Uri developmentBaseUri({TargetPlatform? platform}) {
    if (_definedBaseUrl.isNotEmpty) {
      return _parseBaseUrl(_definedBaseUrl);
    }

    final effectivePlatform = platform ?? defaultTargetPlatform;
    final host = effectivePlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return Uri.parse('http://$host:5080');
  }

  static Uri _parseBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(value, 'BRIDGE_PDX_API_BASE_URL');
    }
    return uri;
  }
}
