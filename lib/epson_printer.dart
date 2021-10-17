import 'dart:async';
import 'package:flutter/services.dart';

class EpsonPrinter {
  static const MethodChannel _channel = MethodChannel('epson_printer');

  static startPrinterDiscovery() {
    _channel.invokeMethod('startDiscovery');
  }

  static void setMethodCallHandler(
      Future<dynamic> Function(MethodCall call) handler) {
    _channel.setMethodCallHandler(handler);
  }
}
