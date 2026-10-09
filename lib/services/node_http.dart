import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// HTTP GET to the node that works while the phone is on the node's own
/// Wi-Fi ("PhytoSense AI", no internet) with mobile data switched on.
///
/// On Android the request is opened on the Wi-Fi network itself (native
/// NodeWifiHttp); without that, Android sends it over mobile data and it never
/// reaches 192.168.4.1. Only this request is routed; Firebase and everything
/// else keep using the default network. Other platforms, tests, or a phone
/// with no Wi-Fi at all use the normal HTTP client.
class NodeHttp {
  NodeHttp._();

  static const _channel = MethodChannel('com.harjeet.phytosense/node_http');

  static Future<http.Response> get(
    Uri uri, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      Map<String, dynamic>? reply;
      try {
        reply = await _channel.invokeMapMethod<String, dynamic>('get', {
          'url': uri.toString(),
          'timeoutMs': timeout.inMilliseconds,
        }).timeout(timeout + const Duration(milliseconds: 700));
      } on MissingPluginException {
        reply = null;
      } on PlatformException {
        reply = null;
      }
      if (reply != null && reply['wifi'] == true) {
        final error = reply['error'];
        if (error != null) throw http.ClientException('$error', uri);
        return http.Response.bytes(
          utf8.encode(reply['body'] as String? ?? ''),
          (reply['status'] as num?)?.toInt() ?? 0,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }
    return http.get(uri, headers: const {'Accept': 'application/json'})
        .timeout(timeout);
  }
}
