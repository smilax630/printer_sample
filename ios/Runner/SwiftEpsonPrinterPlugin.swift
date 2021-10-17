import Flutter
import UIKit

public class SwiftEpsonPrinterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "epson_printer", binaryMessenger: registrar.messenger())
    let instance = SwiftEpsonPrinterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "startDiscovery" {
      EpstonPrinterService().startDiscovery()
    }
    result("iOS " + UIDevice.current.systemVersion)
  }
}
