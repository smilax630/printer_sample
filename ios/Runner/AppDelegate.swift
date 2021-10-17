import UIKit
import Flutter
import Foundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "epson_printer", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
    NSLog("call:")
    NSLog(call.method)
    if call.method == "startDiscovery" {
      EpstonPrinterService(channel: channel).startDiscovery()
    }
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}



class EpstonPrinterService: NSObject, Epos2DiscoveryDelegate{
  let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
      self.channel = channel
  }

  fileprivate var printerList: [Epos2DeviceInfo] = []
  fileprivate var filterOption: Epos2FilterOption = Epos2FilterOption()

  func startDiscovery() -> Int32 {
    NSLog("startDiscovery")
    let result = Epos2Discovery.start(filterOption, delegate: self)
           if result != EPOS2_SUCCESS.rawValue {
            //ShowMsg showErrorEpos(result, method: "start")
        }
    NSLog("result")
    NSLog(String(result))
    return result;
  }

  func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        print("============== onDiscovery")
        let target = deviceInfo?.target
        let deviceName = deviceInfo?.deviceName
        var ipAddress = deviceInfo?.ipAddress
        var macAddress = deviceInfo?.macAddress
        var bdAddress = deviceInfo?.bdAddress
        var printerType = "ip"
        var connectionType = "TCP"
        print(deviceName ?? "")

        if (bdAddress != "") && (ipAddress == "") && (macAddress == "") {
            ipAddress = bdAddress
            macAddress = bdAddress
            printerType = "bluetooth"
            connectionType = "BT"
        } else if (bdAddress == "") && (macAddress != "") {
            bdAddress = macAddress
        }

        let printerObj:[String : Any] = [
            "target": target ?? "",
            "deviceName": deviceName ?? "",
            "ipAddress": ipAddress ?? "",
            "macAddress": macAddress ?? "",
            "bdAddress": bdAddress ?? "",
            "deviceType": NSNumber(value: deviceInfo?.deviceType ?? 0),
            "printerType": printerType,
            "connectionType": connectionType,
            // "printerSeries": NSNumber(value: printerSeries.rawValue),
        ]

    NSLog("onDiscovery:")
    NSLog(printerObj["deviceName"] as! String)
    NSLog(printerObj["ipAddress"] as! String)
    channel.invokeMethod("deviceInfo", arguments: printerObj)
  }

}