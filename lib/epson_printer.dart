import 'dart:async';
import 'dart:ffi';
import 'package:flutter/services.dart';

class EpsonPrinter {
  static const MethodChannel _channel = MethodChannel('epson_printer');

  static Future<EposErrorStatus> startDiscovery() async {
    final result = await _channel.invokeMethod('startDiscovery') as int?;
    final resultStatus =
        EposErrorStatus.values.firstWhere((element) => element.index == result);
    print("startDiscovery result $resultStatus");
    return resultStatus;
  }

  static Future<EposErrorStatus> stopDiscovery() async {
    final result = await _channel.invokeMethod('stopDiscovery') as int?;
    final resultStatus =
        EposErrorStatus.values.firstWhere((element) => element.index == result);
    print("stopDiscovery result $resultStatus");
    return resultStatus;
  }

  static connectDevice() {
    _channel.invokeMethod('connectDevice');
  }

  static Future<bool> initilizePrinter() async {
    final result = await _channel.invokeMethod('initilizePrinter') as bool;
    print(result);
    return result;
  }

  static Future<bool> createReceiptData() async {
    final result = await _channel.invokeMethod('createReceiptData') as bool;
    print(result);
    return result;
  }

  static Printer? onDiscovery() {
    _setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'deviceInfo':
          final printerMap = call.arguments as Map<String, dynamic>;
          print(call.arguments);
          return Printer(
            target: printerMap["target"],
            deviceName: printerMap["deviceName"],
            ipAddress: printerMap["ipAddress"],
            macAddress: printerMap["macAddress"],
            bdAddress: printerMap["bdAddress"],
            deviceType: DeviceType.values.firstWhere(
                (element) => element.index == printerMap["deviceType"]),
          );
        default:
          print(
              "Callback Method Not Found: ${call.method}\nArguments: ${call.arguments}");
      }
    });
  }

  static void _setMethodCallHandler(
      Future<dynamic> Function(MethodCall call) handler) {}
}

class Printer {
  Printer(
      {required this.target,
      required this.deviceName,
      required this.ipAddress,
      required this.macAddress,
      required this.bdAddress,
      required this.deviceType});
  final String target;
  final String deviceName;
  final String ipAddress;
  final String macAddress;
  final String bdAddress;
  final DeviceType deviceType;
}

enum DeviceType {
  epos2TypeAll,
  epos2TypePriter,
  epos2TypeHybridPriter,
  epos2TypeDisplay,
  epos2TypeKeyBoard,
  epos2TypeScanner,
  epos2TypeSerial,
  epos2TypeCchanger,
  epos2TypePodKeyBoard,
  epos2TypeCat,
  epos2TypeMsr,
  epos2TypeOtherPeripheral,
  epos2Typegfe,
}

enum EposErrorStatus {
  success,
  errparams,
  errConnect,
  errTimeout,
  errMemory,
  errIleegal,
  errProcessing,
  errNotFoud,
  errInUse,
  errTypeInvalid,
  errDisconnect,
  errAlreadyOpened,
  errAlreadyUsed,
  errBoxCountOver,
  errBoxClientOver,
  errUnSupported,
  errDeviceBusy,
  errRecoveryFailure,
  errFailure
}

    // EPOS2_ERR_PARAM,
    // EPOS2_ERR_CONNECT,
    // EPOS2_ERR_TIMEOUT,
    // EPOS2_ERR_MEMORY,
    // EPOS2_ERR_ILLEGAL,
    // EPOS2_ERR_PROCESSING,
    // EPOS2_ERR_NOT_FOUND,
    // EPOS2_ERR_IN_USE,
    // EPOS2_ERR_TYPE_INVALID,
    // EPOS2_ERR_DISCONNECT,
    // EPOS2_ERR_ALREADY_OPENED,
    // EPOS2_ERR_ALREADY_USED,
    // EPOS2_ERR_BOX_COUNT_OVER,
    // EPOS2_ERR_BOX_CLIENT_OVER,
    // EPOS2_ERR_UNSUPPORTED,
    // EPOS2_ERR_DEVICE_BUSY,
    // EPOS2_ERR_RECOVERY_FAILURE,
    // EPOS2_ERR_FAILURE = 255