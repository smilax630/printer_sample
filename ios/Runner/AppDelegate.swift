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
    if call.method == "startDiscovery" {
      result(EposDiscoveryService(channel: channel).startDiscovery())
    }
    if call.method == "stopDiscovery" {
      result(EposDiscoveryService(channel: channel).stopDiscovery())
    }
    if call.method == "initilizePrinter" {
      result(EposPrintService(channel: channel).initilizePrinter())
    }
    if call.method == "createReceiptData" {
      result(EposPrintService(channel: channel).createReceiptData())
    }
    // if call.method == "connectPrinter" {
    //   NSLos(call.arguments)
    //   result(EposPrintService(channel: channel).connectPrinter())
    // }
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}



class EposDiscoveryService: NSObject, Epos2DiscoveryDelegate{
  let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
      self.channel = channel
  }

  fileprivate var printerList: [Epos2DeviceInfo] = []
  fileprivate var filterOption: Epos2FilterOption = Epos2FilterOption()

  fileprivate var printer: Epos2Printer?
    
  func startDiscovery() -> Int32 {
    NSLog("startDiscovery")
    filterOption.deviceType = EPOS2_TYPE_PRINTER.rawValue

    let result = Epos2Discovery.start(filterOption, delegate: self)
           if result != EPOS2_SUCCESS.rawValue {
            //ShowMsg showErrorEpos(result, method: "start")
        }
    return result;
  }
  func stopDiscovery() -> Int32 {
    NSLog("stopDiscovery")
    return Epos2Discovery.stop()
  }

  func connectDevice() -> Int32?  {
      let btConnection = Epos2BluetoothConnection()
      let BDAddress = NSMutableString()
      let result = btConnection?.connectDevice(BDAddress)
      return result
    }

  func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        NSLog("============== onDiscovery")
        let target = deviceInfo?.target
        let deviceName = deviceInfo?.deviceName
        var ipAddress = deviceInfo?.ipAddress
        var macAddress = deviceInfo?.macAddress
        var bdAddress = deviceInfo?.bdAddress
        var printerType = "ip"
        var connectionType = "TCP"

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

class EposPrintService: NSObject, Epos2PtrReceiveDelegate{
  let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
      self.channel = channel
  }
  fileprivate var printer: Epos2Printer?
    
  fileprivate var valuePrinterSeries: Epos2PrinterSeries = EPOS2_TM_T70
  fileprivate var valuePrinterModel: Epos2ModelLang = EPOS2_MODEL_JAPANESE

  func initilizePrinter() -> Bool {
    printer = Epos2Printer(printerSeries: valuePrinterSeries.rawValue, lang: valuePrinterModel.rawValue)
    
    if printer == nil {
        return false
    }
    printer!.setReceiveEventDelegate(self)
    
    return true
  }
  func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
    NSLog("プリント完了")
    // MessageView.showResult(code, errMessage: makeErrorMessage(status))
        
      // dispPrinterWarnings(status)
      // updateButtonState(true)
      
      DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
          // self.disconnectPrinter()
          })
  }

      func createReceiptData() -> Bool {
        let barcodeWidth = 2
        let barcodeHeight = 100
        
        var result = EPOS2_SUCCESS.rawValue
        
        let textData: NSMutableString = NSMutableString()
        let logoData = UIImage(named: "store.png")
        
        if logoData == nil {
            return false
        }

        result = printer!.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            // MessageView.showErrorEpos(result, method:"addTextAlign")
            return false;
        }
        
        result = printer!.add(logoData, x: 0, y:0,
            width:Int(logoData!.size.width),
            height:Int(logoData!.size.height),
            color:EPOS2_COLOR_1.rawValue,
            mode:EPOS2_MODE_MONO.rawValue,
            halftone:EPOS2_HALFTONE_DITHER.rawValue,
            brightness:Double(EPOS2_PARAM_DEFAULT),
            compress:EPOS2_COMPRESS_AUTO.rawValue)
        
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addImage")
            return false
        }

        // Section 1 : Store information
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addFeedLine")
            return false
        }
        
        textData.append("THE STORE 123 (555) 555 – 5555\n")
        textData.append("STORE DIRECTOR – John Smith\n")
        textData.append("\n")
        textData.append("7/01/07 16:58 6153 05 0191 134\n")
        textData.append("ST# 21 OP# 001 TE# 01 TR# 747\n")
        textData.append("------------------------------\n")
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        textData.setString("")
        
        // Section 2 : Purchaced items
        textData.append("400 OHEIDA 3PK SPRINGF  9.99 R\n")
        textData.append("410 3 CUP BLK TEAPOT    9.99 R\n")
        textData.append("445 EMERIL GRIDDLE/PAN 17.99 R\n")
        textData.append("438 CANDYMAKER ASSORT   4.99 R\n")
        textData.append("474 TRIPOD              8.99 R\n")
        textData.append("433 BLK LOGO PRNTED ZO  7.99 R\n")
        textData.append("458 AQUA MICROTERRY SC  6.99 R\n")
        textData.append("493 30L BLK FF DRESS   16.99 R\n")
        textData.append("407 LEVITATING DESKTOP  7.99 R\n")
        textData.append("441 **Blue Overprint P  2.99 R\n")
        textData.append("476 REPOSE 4PCPM CHOC   5.49 R\n")
        textData.append("461 WESTGATE BLACK 25  59.99 R\n")
        textData.append("------------------------------\n")
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        textData.setString("")

        
        // Section 3 : Payment infomation
        textData.append("SUBTOTAL                160.38\n");
        textData.append("TAX                      14.43\n");
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addText")
            return false
        }
        textData.setString("")
        
        result = printer!.addTextSize(2, height:2)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addTextSize")
            return false
        }
        
        result = printer!.addText("TOTAL    174.81\n")
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        
        result = printer!.addTextSize(1, height:1)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addTextSize")
            return false;
        }
        
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addFeedLine")
            return false;
        }
        
        textData.append("CASH                    200.00\n")
        textData.append("CHANGE                   25.19\n")
        textData.append("------------------------------\n")
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addText")
            return false
        }
        textData.setString("")
        
        // Section 4 : Advertisement
        textData.append("Purchased item total number\n")
        textData.append("Sign Up and Save !\n")
        textData.append("With Preferred Saving Card\n")
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        textData.setString("")
        
        result = printer!.addFeedLine(2)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addFeedLine")
            return false
        }
        
        result = printer!.addBarcode("01209457",
            type:EPOS2_BARCODE_CODE39.rawValue,
            hri:EPOS2_HRI_BELOW.rawValue,
            font:EPOS2_FONT_A.rawValue,
            width:barcodeWidth,
            height:barcodeHeight)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addBarcode")
            return false
        }
        
        result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            // MessageView.showErrorEpos(result, method:"addCut")
            return false
        }
        
        return true
    }
}