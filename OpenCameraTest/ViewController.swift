//
//  ViewController.swift
//  OpenCameraTest
//
//  Created by 조기현 on 17/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

import UIKit

class ViewController: UIViewController,CameraDelegate {

    var myCamera:Camera!
    var img:UIImage!
    
    
    @IBOutlet weak var captureView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        myCamera = Camera(controller: self, andImageView: imageView, andCapture: captureView)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        imageView.contentMode = .scaleAspectFit // OR .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    @IBAction func onClick(_ sender: Any) {
        //myCamera.stop()
        myCamera.capture()
    }
    
    func showFrame(_ image:UIImage){
        DispatchQueue.main.async {
            self.imageView.image = image
            self.imageView.setNeedsDisplay()
        }
    }
    
    func showCapturedFrame(_ image:UIImage){
        img = image;
        DispatchQueue.main.async {
            self.captureView.image = image
            self.captureView.setNeedsDisplay()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        myCamera.start()
    }
    
    // Stop it when it disappears
    override func viewWillDisappear(_ animated: Bool) {
        myCamera.stop()
    }


}

