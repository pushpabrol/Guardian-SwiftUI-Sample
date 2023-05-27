

import SwiftUI
import QRCodeReader
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    var completionHandler: ((String?) -> ())?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completionHandler)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ScannerView>) -> QRCodeReaderViewController {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            $0.showTorchButton = true
        }

        let viewController = QRCodeReaderViewController(builder: builder)
        viewController.delegate = context.coordinator

        return viewController
    }

    func updateUIViewController(_ uiViewController: QRCodeReaderViewController, context: UIViewControllerRepresentableContext<ScannerView>) {}

    class Coordinator: NSObject, QRCodeReaderViewControllerDelegate {
        var completion: ((String?) -> ())?
        
        init(completion: ((String?) -> ())?) {
            self.completion = completion
        }

        func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
            reader.stopScanning()
            reader.dismiss(animated: true) {
                self.completion?(result.value)
            }
        }

        func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {}

        func readerDidCancel(_ reader: QRCodeReaderViewController) {
            reader.stopScanning()
            reader.dismiss(animated: true) {
                self.completion?(nil)
            }
        }
    }
}

