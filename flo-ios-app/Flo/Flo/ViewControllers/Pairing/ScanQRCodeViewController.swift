//
//  ScanQRCodeViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 18/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyJSON

internal class ScanQRCodeViewController: FloBaseViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    public var device: DeviceToPair!
    fileprivate var waitingQRConfirmation = false
    fileprivate var cameraLayer: AVCaptureVideoPreviewLayer!
    fileprivate let captureSession = AVCaptureSession()
    fileprivate var captureDevice: AVCaptureDevice?
    fileprivate let supportedBarCodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.aztec]
    
    @IBOutlet fileprivate weak var pairTitleLabel: UILabel!
    @IBOutlet fileprivate weak var cameraView: UIView!
    @IBOutlet fileprivate weak var sightImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarWithCancel(returningToRoot: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let deviceQRCode = device.qrCode, let certificate = deviceQRCode.websocketCertDer.base64DecodedWithISO().data(using: .isoLatin1) {
            ICDPairingWebSocketModel.sharedInstance.setSelfSignedCertificate(certificate)
            performSegue(withIdentifier: DeviceWiFiViewController.storyboardId, sender: nil)
        } else {
            waitingQRConfirmation = false
            pairTitleLabel.text = "pair".localized + " " + device.nickname
            sightImageView.layer.zPosition = 1
            setupCamera()
        }
    }
    
    // MARK: - Camera setup
    fileprivate func setupCamera() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            if captureSession.inputs.isEmpty {
                captureSession.sessionPreset = .high
                let availableDevices = AVCaptureDevice.devices()
                for device in availableDevices {
                    if device.hasMediaType(.video) && device.position == .back {
                        captureDevice = device
                        break
                    }
                }
                
                if captureDevice != nil {
                    beginCaptureSession()
                } else {
                    showPopup(title: "error_popup_title".localized, description: "we_didnt_find_a_camera_to_scan".localized)
                }
            } else {
                captureSession.startRunning()
            }
        } else {
            AVCaptureDevice.requestAccess(for: .video) { accessGranted in
                DispatchQueue.main.async {
                    if accessGranted {
                        self.setupCamera()
                    } else {
                        self.showCameraAccessError()
                    }
                }
            }
        }
    }
    
    fileprivate func beginCaptureSession() {
        if !captureSession.isRunning {
            do {
                if let device = captureDevice {
                    try captureSession.addInput(AVCaptureDeviceInput(device: device))
                    let captureMetadataOutput = AVCaptureMetadataOutput()
                    captureSession.addOutput(captureMetadataOutput)
                    // Set delegate and use the default dispatch queue to execute the call back
                    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                    captureMetadataOutput.metadataObjectTypes = [.qr]
                    // Detect all the supported bar code
                    captureMetadataOutput.metadataObjectTypes = supportedBarCodes
                    cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    
                    setCameraLayerInBounds()
                }
            } catch let exception as NSError {
                LoggerHelper.log(exception)
                
                showCameraAccessError()
            }
        }
    }
    
    fileprivate func setCameraLayerInBounds() {
        cameraLayer.frame = CGRect(origin: .zero, size: cameraView.frame.size)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(cameraLayer)
        captureSession.startRunning()
    }
    
    fileprivate func showCameraAccessError() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            showPopup(
                title: "camera_access_required_to_continue".localized,
                description: "please_go_to_settings_and_allow_camera_access".localized,
                acceptButtonText: "device_settings".localized,
                acceptButtonAction: {
                    UIApplication.shared.openURL(url)
                },
                cancelButtonText: "cancel".localized,
                cancelButtonAction: {
                    self.goToRoot()
                }
            )
        }
    }
    
    // MARK: - Camera QR scanning protocol methods
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if !waitingQRConfirmation {
            // Check if metadataObjects contains at least one object
            if metadataObjects.isEmpty { return }
            
            // Get the metadata object
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                supportedBarCodes.contains(metadataObject.type),
                let qrCode = cameraLayer.transformedMetadataObject(for: metadataObject),
                sightImageView.frame.contains(qrCode.bounds),
                var scannedCode = metadataObject.stringValue {
                waitingQRConfirmation = true
                
                if let scannedCodeModel: FloICDPurchaseCodeModel = scannedCode.convertToObject() {
                    let scannedData = ["data": scannedCodeModel.purchaseICDJson as AnyObject]
                    
                    showLoadingSpinner("loading".localized)
                    confirmScannedData(scannedData)
                } else {
                    scannedCode = scannedCode.replacingOccurrences(of: " ", with: "")
                    let scannedData = ["data": scannedCode as AnyObject]
                    
                    showLoadingSpinner("loading".localized)
                    confirmScannedData(scannedData)
                }
            }
        }
    }
    
    // MARK: - Send scanned data to server
    fileprivate func confirmScannedData(_ data: [String: AnyObject]) {
        FloApiRequest(controller: "v2/devices/pair/init", method: .post, queryString: nil, data: data, done: { (error, data) in
            self.hideLoadingSpinner()
            
            if let e = error {
                var errorTitle = e.title
                var errorMsg = e.message
                if e.status != nil && e.status! == 409 {
                    errorTitle = "flo_error".localized + " 004"
                    errorMsg = "device_already_paired".localized
                }
                self.showPopup(
                    title: errorTitle,
                    description: errorMsg,
                    buttonText: "ok".localized,
                    buttonAction: {
                        self.waitingQRConfirmation = false
                    }
                )
            } else {
                self.handleConfirmationResonse(data)
            }
        }).secureFloRequest()
    }
    
    fileprivate func handleConfirmationResonse(_ data: AnyObject?) {
        super.hideLoadingSpinner()
        
        if let deviceQRCode = DeviceQRCode(data), let certificate = deviceQRCode.websocketCertDer.base64DecodedWithISO().data(using: .isoLatin1) {
            ICDPairingWebSocketModel.sharedInstance.setSelfSignedCertificate(certificate)
            device.qrCode = deviceQRCode
            performSegue(withIdentifier: DeviceWiFiViewController.storyboardId, sender: nil)
        } else {
            self.showPopup(
                title: "error_popup_title".localized,
                description: "purchase_not_found".localized,
                buttonText: "ok".localized,
                buttonAction: {
                    self.waitingQRConfirmation = false
                }
            )
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? DeviceWiFiViewController {
            viewController.device = device
        }
    }

}
