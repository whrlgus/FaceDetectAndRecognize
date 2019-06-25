//
//  ViewController.swift
//  opencvframeworktest
//
//  Created by 조기현 on 19/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

import UIKit

class ViewController: UIViewController,CameraDelegate {
    
    var videoCamera:Camera!
    //var newLabel:Int32!
    
    @IBOutlet weak var videoImageView: UIImageView!
    
    @IBOutlet weak var resultTextField: UITextField!
    
    @IBOutlet weak var trainButton: UIButton!
    
    @IBOutlet weak var recognizeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //newLabel = Int32(UserDefaults.standard.integer(forKey: "newLabel"))
        initCamera()
        initVideoImageView()
        //recognizeButton.isEnabled = false
    }
    
    @IBAction func trainOnClicked(_ sender: Any) {
        NSLog("trainBtnClicked")
        videoCamera.trainBtnClicked=true
        videoCamera.predictBtnClicked=false
        trainButton.isEnabled = false
        recognizeButton.isEnabled=false
        videoCamera.trainFaces()
        
    }
    
    @IBAction func recogOnClicked(_ sender: Any) {
        NSLog("trainBtnClicked")
        videoCamera.predictBtnClicked=true
        trainButton.isEnabled = true
        recognizeButton.isEnabled=false
        //videoCamera.predictFace()
    }
    
    func initCamera(){
        var newLabel:Int32=Int32(0)
        videoCamera = Camera(viewController: self, andVideoImageView: videoImageView, andResultTextField: resultTextField, andNewLable: &newLabel)
        videoCamera.trainBtnClicked=false
        videoCamera.predictBtnClicked=false
    }
    
    func initVideoImageView(){
        videoImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        videoImageView.contentMode = .scaleAspectFit//.scaleAspectFit OR .scaleAspectFill
        videoImageView.clipsToBounds = true
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        videoCamera.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCamera.stop()
    }
    func updateImageView(_ image: UIImage) {
        DispatchQueue.main.async {
            NSLog("main dispatch 시작")
            self.videoImageView.image = image
            self.videoImageView.setNeedsDisplay()
        }
        
    }
    
    func enableRecognizeButton() {
        videoCamera.trainBtnClicked=false
        DispatchQueue.main.async {
            
            self.recognizeButton.isEnabled=true
            self.recognizeButton.setNeedsDisplay()
        }
    }
    
}

