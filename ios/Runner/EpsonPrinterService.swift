import Foundation

class EpstonPrinterService: NSObject, Epos2DiscoveryDelegate{

  fileprivate var printerList: [Epos2DeviceInfo] = []
  fileprivate var filterOption: Epos2FilterOption = Epos2FilterOption()

  func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
    print(deviceInfo!)
    printerList.append(deviceInfo)
  }
  
  func startDiscovery() {
    let result = Epos2Discovery.start(filterOption, delegate: self)
           if result != EPOS2_SUCCESS.rawValue {
            //ShowMsg showErrorEpos(result, method: "start")
        }
  }
  
}
