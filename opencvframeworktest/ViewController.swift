//
//  ViewController.swift
//  opencvframeworktest
//
//  Created by 조기현 on 19/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var videoCamera:Camera!
    
    @IBOutlet weak var videoImageView: UIImageView!
    
    @IBOutlet weak var captureImageView: UIImageView!
    
    
    @IBOutlet weak var resultTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoCamera = Camera(controller: self, andVideoImageView: videoImageView, andCapture: captureImageView, andResultTextField: resultTextField)
        initVideoImageView()
    }
    
    func initVideoImageView(){
        videoImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        videoImageView.contentMode = .scaleAspectFit//.scaleAspectFit // OR .scaleAspectFill
        videoImageView.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        videoImageView.addGestureRecognizer(tap)
        videoImageView.isUserInteractionEnabled=true
        
    }
    
    @objc func doubleTapped() {
        videoCamera.capture()
    }

    override func viewDidAppear(_ animated: Bool) {
        videoCamera.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        videoCamera.stop()
    }
}

