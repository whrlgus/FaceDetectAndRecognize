//
//  Camera.m
//  OpenCameraTest
//
//  Created by 조기현 on 17/06/2019.
//  Copyright © 2019 none. All rights reserved.
//
#ifndef __cplusplus
#import <opencv2/opencv.hpp>
#endif
#import <opencv2/videoio/cap_ios.h>
#import "opencv2/imgproc/imgproc.hpp"
#import "opencv2/imgcodecs/ios.h"
#import "Camera.h"



using namespace cv;
// Class extension to adopt the delegate protocol
@interface Camera () <CvVideoCameraDelegate>
{
}
@end
@implementation Camera
{
    
    UIViewController<CameraDelegate> * delegate;
    UIImageView * imageView;
    UIImageView* captureView;
    CvVideoCamera * videoCamera;
    UIImage * uiImage;
    
}

-(id)initWithController:(UIViewController<CameraDelegate>*)c andImageView:(UIImageView*)iv andCaptureView:(UIImageView*)cv
{
    delegate = c;
    imageView = iv;
    captureView = cv;
    
    //videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    videoCamera = [[CvVideoCamera alloc] init];
    
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack; // Use the back camera
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait; // Ensure proper orientation
    videoCamera.rotateVideo = YES; // Ensure proper orientation
    videoCamera.defaultFPS = 30; // How often 'processImage' is called, adjust based on the amount/complexity 
    videoCamera.delegate = self;
    
    return self;
}
// This #ifdef ... #endif is not needed except in special situations
#ifdef __cplusplus
- (void)processImage:(Mat&)image
{
    Mat image_copy;
    cvtColor(image, image_copy, COLOR_BGRA2RGB);
    uiImage = MatToUIImage(image_copy);
    [delegate showFrame:uiImage];
    
}
#endif

-(void)capture{
    [delegate showCapturedFrame:uiImage];
}


-(void)start
{
    [videoCamera start];
}

-(void)stop{
    [videoCamera stop];
}
@end
