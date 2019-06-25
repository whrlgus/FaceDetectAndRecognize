//
//  ViewController.swift
//  FaceDetectAndRecognize
//
//  Created by 조기현 on 23/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

import UIKit

class ViewController: UIViewController,CameraDelegate {
    
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var trainButton: UIButton!
    @IBOutlet weak var predictButton: UIButton!
    
    var videoCamera:Camera!
    var popUpVC:PopUpViewController!
    
    @IBAction func trainBtnOnClicked(_ sender: Any) {
        
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SBPopUpID") as! PopUpViewController
        popUpVC = popOverVC
        
        self.addChild(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParent: self)
        
        videoCamera.change(TRAIN)
    }
    
    @IBAction func predictBtnOnClicked(_ sender: Any) {
        videoCamera.change(PREDICT)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initCamera()
        initVideoImageView()
    }
    
    func initCamera(){
        videoCamera = Camera(viewController: self)
        videoCamera.start()
    }
    func initVideoImageView(){
        videoImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        videoImageView.contentMode = .scaleAspectFit//.scaleAspectFit OR .scaleAspectFill
        videoImageView.clipsToBounds = true
        
    }

    func captureFace(_ face: UIImage){
        popUpVC.captureImageView.image = face
    }

    func updateImageView(_ image: UIImage) {
        videoImageView.image = image
    }
    
    func showPrecise(_ msg: String) {
        textField.text = msg
    }
    func closePopUp() {
        DispatchQueue.main.async {
            self.popUpVC.removeAnimate()
        }
    }
}

