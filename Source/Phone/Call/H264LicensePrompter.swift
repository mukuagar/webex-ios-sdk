// Copyright 2016-2019 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

class H264LicensePrompter {
    
    private let metrics: MetricsEngine
    
    var disable: Bool {
        get {
            return UserDefaults.sharedInstance.isVideoLicenseActivationDisabled
        }
        set {
            UserDefaults.sharedInstance.isVideoLicenseActivationDisabled = true
        }
    }
    
    init(metrics: MetricsEngine) {
        self.metrics = metrics
    }
    
    
    func check(completionHandler: @escaping ((Bool) -> Void)) {
        DispatchQueue.main.async {
            if UserDefaults.sharedInstance.isVideoLicenseActivated || self.disable {
                completionHandler(true)
            }
            else {
                var closed:(() -> Void)?
                let completion:((Bool) -> Void) = { activate in
                    completionHandler(activate)
                    closed?()
                }
                
                let alertTitle = "Activate License"
                let alertMessage = "To enable video calls, activate a free video license (H.264 AVC) from Cisco. By selecting 'Activate', you accept the Cisco End User License Agreement and Notices."
                #if swift(>=4.2)
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "Activate", style: UIAlertAction.Style.default) { _ in
                    SDKLogger.shared.info("Video license has been activated")
                    UserDefaults.sharedInstance.isVideoLicenseActivated = true
                    self.metrics.trackVideoLicenseActivation()
                    completion(true)
                })
                alertController.addAction(UIAlertAction(title: "View License", style: UIAlertAction.Style.default) { _ in
                    SDKLogger.shared.info("Video license opened for viewing")
                    completion(false)
                    if let url = URL(string: "http://www.openh264.org/BINARY_LICENSE.txt") {
                        UIApplication.shared.open(url, options:[:], completionHandler: nil)
                    }
                })
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { _ in
                    SDKLogger.shared.warn("Video license has not been activated")
                    completion(false)
                })
                #else
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Activate", style: UIAlertActionStyle.default) { _ in
                SDKLogger.shared.info("Video license has been activated")
                UserDefaults.sharedInstance.isVideoLicenseActivated = true
                self.metrics.trackVideoLicenseActivation()
                completion(true)
                })
                alertController.addAction(UIAlertAction(title: "View License", style: UIAlertActionStyle.default) { _ in
                SDKLogger.shared.info("Video license opened for viewing")
                completion(false)
                if let url = URL(string: "http://www.openh264.org/BINARY_LICENSE.txt") {
                UIApplication.shared.open(url, options:convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }
                })
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                SDKLogger.shared.warn("Video license has not been activated")
                completion(false)
                })
                #endif
                
                alertController.present(true, completion: nil, closed: &closed)
            }
        }
    }
    
    // Used for development only, to reset video license settings.
    func reset() {
        UserDefaults.sharedInstance.resetVideoLicenseActivation()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
