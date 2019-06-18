#ifndef __cplusplus
#import <opencv2/opencv.hpp>
#endif
#import <opencv2/videoio/cap_ios.h>
#import "opencv2/imgproc/imgproc.hpp"
#import "opencv2/imgcodecs/ios.h"
#import <opencv2/objdetect/objdetect.hpp>
#import "Camera.h"

using namespace cv;
// Class extension to adopt the delegate protocol
@interface Camera () <CvVideoCameraDelegate>
{
}
@end

@implementation Camera
{
    CascadeClassifier face_cascade;
    CascadeClassifier eye_cascade;
    
    UIViewController<CameraDelegate> * delegate;
    UIImageView * imageView;
    UIImageView* captureView;
    CvVideoCamera * videoCamera;
    UIImage * uiImage;
    
    
}

-(id)initWithController:(UIViewController<CameraDelegate>*)c andImageView:(UIImageView*)iv andCaptureView:(UIImageView*)cv
{
    
    // get main app bundle
    NSBundle * appBundle = [NSBundle mainBundle];
    
    // constant file name
    NSString * cascadeName = @"haarcascade_frontalface_default";
    NSString * cascadeType = @"xml";
    
    // get file path in bundle
    NSString * cascadePathInBundle = [appBundle pathForResource: cascadeName ofType: cascadeType];
    
    // convert NSString to std::string
    std::string faceCascadePath([cascadePathInBundle UTF8String]);
    
    
    // constant file name
    cascadeName = @"haarcascade_eye";
    
    // get file path in bundle
    cascadePathInBundle = [appBundle pathForResource: cascadeName ofType: cascadeType];
    
    // convert NSString to std::string
    std::string eyeCascadePath([cascadePathInBundle UTF8String]);
    
    // load cascade
    if (face_cascade.load(faceCascadePath)&&eye_cascade.load(eyeCascadePath)){
        NSLog(@"Load complete");
    }else{
        NSLog(@"Load error");
        return nil;
    }

    
    
    
    delegate = c;
    imageView = iv;
    captureView = cv;
    
    //videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    videoCamera = [[CvVideoCamera alloc] init];
    
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack; // Use the back camera
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait; // Ensure proper orientation
    videoCamera.rotateVideo = YES; // Ensure proper orientation
    videoCamera.defaultFPS = 60; // How often 'processImage' is called, adjust based on the amount/complexity
    videoCamera.delegate = self;
    
    return self;
}



// This #ifdef ... #endif is not needed except in special situations
//#ifdef __cplusplus
- (void)processImage:(Mat&)image
{
    Mat image_copy;
    cvtColor(image, image_copy, COLOR_BGRA2GRAY);
    equalizeHist( image_copy, image_copy );
    
    uiImage = MatToUIImage(image_copy);
    [delegate showFrame:uiImage];
    
    std::vector<cv::Rect> faces;
    std::vector<cv::Rect> eyes;
    
    //-- Detect faces
    face_cascade.detectMultiScale(image_copy, faces);
    
    if(faces.size()!=1){
        return;
    }
    
    
    
    
    eye_cascade.detectMultiScale(image_copy, eyes);
    
    
    
    if(!faces.empty()&&!eyes.empty()){
        NSLog(@"얼굴 찾음");
        
        
        Mat croppedImg = image_copy;//(faces[0]);
        Scalar blue(0,0,255);
        Scalar green(0,255,0);
        Scalar red(255,0,0);
//
//        faces[0].x=100;
//        faces[0].y=100;
//        faces[0].width=100;
//        faces[0].height=100;
        
        cv::Point p;
        for(int i=0;i<faces.size();++i){
            p.x = faces[i].x;
            p.y = faces[i].y;
            rectangle(croppedImg, faces[i], blue,10);
            putText(croppedImg, std::to_string(i), p, 5, 5, red,5);
            
        }
        for(int i=0;i<eyes.size();++i){
            p.x = eyes[i].x;
            p.y = eyes[i].y;
            rectangle(croppedImg, eyes[i], green,10);
            putText(croppedImg, std::to_string(i), p, 5, 5, red,5);
            
        }
        
        uiImage = MatToUIImage(croppedImg);
        [delegate showCapturedFrame:uiImage];
        
        
        cv::Rect r = faces[0];
        NSLog(@"face : %i %i %i %i",r.x,r.y,r.width,r.height);
        r = eyes[0];
        NSLog(@"face : %i %i %i %i",r.x,r.y,r.width,r.height);
        r = eyes[1];
        NSLog(@"face : %i %i %i %i",r.x,r.y,r.width,r.height);
    }else{
        NSLog(@"얼굴 없음");
        
    }
    
    
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        NSLog(@"saved");
    }
}


//#endif

-(void)capture{
    [delegate showCapturedFrame:uiImage];
    UIImageWriteToSavedPhotosAlbum(uiImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}


-(void)start
{
    [videoCamera start];
}

-(void)stop{
    [videoCamera stop];
}
@end
