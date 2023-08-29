//
//  ImagePicker.swift
//  WePost
//
//  Created by zhubch on 2017/4/6.
//  Copyright © 2017年 happyiterating. All rights reserved.
//

import Foundation
import Photos


class ImagePicker: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    weak var vc: UIViewController?
    
    var pickCompletionHanlder: ((UIImage)->Void)?
    
    init(viewController: UIViewController, completionHanlder:((UIImage)->Void)?) {
        vc = viewController
        pickCompletionHanlder = completionHanlder
        super.init()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismissVC(completion: nil)

        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        guard image != nil else {
            return
        }
        pickCompletionHanlder?(image!)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismissVC(completion: nil)
    }
    
    func pickFromLibray() {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        switch authStatus {
        case .denied:
            vc?.showAlert(title: "PhotoError", message: "EnablePhotoTips", actionTitles: ["Cancel","Settings"]) { (index) in
                if index == 1 {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ [unowned self] (status) in
                if status == .authorized {
                    self.showImagePickerFor(sourceType: .photoLibrary)
                }
            })
        case .authorized:
            showImagePickerFor(sourceType: .photoLibrary)
        default:
            showImagePickerFor(sourceType: .photoLibrary)
        }
    }
    
    func pickFromCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .denied:
            vc?.showAlert(title: "CameraError", message: "EnableCameraTips", actionTitles: ["Cancel","Settings"]) { (index) in
                if index == 1 {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ [unowned self] (status) in
                if status == .authorized {
                    self.showImagePickerFor(sourceType: .camera)
                }
            })
        case .authorized:
            showImagePickerFor(sourceType: .camera)
        default:
            showImagePickerFor(sourceType: .camera)
        }
    }
    
    func showImagePickerFor(sourceType: UIImagePickerController.SourceType) {
        DispatchQueue.main.async {
            let imagePickerVc = UIImagePickerController()
            imagePickerVc.modalPresentationStyle = .formSheet
            imagePickerVc.sourceType = sourceType
            imagePickerVc.delegate = self
            self.vc?.presentVC(imagePickerVc)
        }
    }
}



