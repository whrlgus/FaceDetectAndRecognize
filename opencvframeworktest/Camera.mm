//
//  Camera.m
//  opencvframeworktest
//
//  Created by 조기현 on 19/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

//#ifndef __cplusplus
#import "opencv2/opencv.hpp"
#import "opencv2/imgcodecs/ios.h"
//#endif
#import "opencv2/videoio/cap_ios.h"
#import "opencv2/face/facerec.hpp"

#import "Camera.h"

using namespace cv;
using namespace std;

@interface Camera () <CvVideoCameraDelegate>
{
}
@end

@implementation Camera{
    UIViewController* viewController;
    UIImageView* videoImageView;
    UIImageView* captureImageView;
    UITextField* resultTextField;
    CvVideoCamera* videoCamera;
    CascadeClassifier face_cascade, eye_cascade;
    vector<cv::Rect> faces_with_low_prob,eyes_with_low_prob;
    vector<cv::Rect*> faces_with_high_prob;
    Ptr<cv::face::LBPHFaceRecognizer> model;
    vector<cv::Mat> trainFaces;
    vector<int> trainLabels;
    bool isTrained;
    
}


-(instancetype)initWithController:(UIViewController*)c andVideoImageView:(UIImageView*)viv andCaptureImageView:(UIImageView*)civ andResultTextField:(UITextField*)rtf;
{
    viewController = c;
    videoImageView = viv;
    captureImageView = civ;
    resultTextField = rtf;
    [self initCamera];
    [self initCascadeClassifier];
    model = cv::face::LBPHFaceRecognizer::create();
    //trainFaces.clear();
    //trainLabels.clear();
    isTrained=false;
    
    return self;
}

-(void)initCascadeClassifier
{
    NSBundle * appBundle = [NSBundle mainBundle];
    NSString * cascadePathInBundle = [appBundle pathForResource: @"haarcascade_frontalface_default" ofType: @"xml"];
    std::string faceCascadePath([cascadePathInBundle UTF8String]);
    cascadePathInBundle = [appBundle pathForResource: @"haarcascade_eye" ofType: @"xml"];
    std::string eyeCascadePath([cascadePathInBundle UTF8String]);
    if (!face_cascade.load(faceCascadePath)||!eye_cascade.load(eyeCascadePath)) NSLog(@"Load error");
}

-(void)initCamera
{
    videoCamera = [[CvVideoCamera alloc] init];
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    videoCamera.delegate = self;
}

- (void)processImage:(cv::Mat&)image
{
    
    // andMinNumOfDetection의 최소 설정값은 2
    [self detectFace:image andMinNumOfDetection:2];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        for(auto &face : self->faces_with_high_prob)
//            rectangle(image, *face, Scalar(255,0,0),10);
//        self->videoImageView.image = MatToUIImage(image);
//    });
    
    int numOfFaces = (int)faces_with_high_prob.size();
    if(numOfFaces==1){
        
        Mat face = image(*faces_with_high_prob[0]);
        cvtColor(face, face, COLOR_RGBA2GRAY);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->videoImageView.image = MatToUIImage(face);
        });
        
        
        if(trainFaces.size()<50){
            dispatch_async(dispatch_get_main_queue(), ^{
                self->resultTextField.text = [NSString stringWithFormat:@"학습중 %d%%",2*self->trainFaces.size()];
            });
            NSLog(@"%d",(int)trainFaces.size());
            trainFaces.push_back(face);
//            if(trainFaces.size()==1){
//                for(int i=0;i<30;++i) trainFaces.push_back(trainFaces[0]);
//            }
        }else{
            trainLabels.assign(trainFaces.size(),0);
            [self trainFaces];
            isTrained=true;
        }
        
        if(isTrained){
            [self predictFace:face];
        }
        
    }
    else if(numOfFaces>1) NSLog(@"얼굴이 여러개");
    else NSLog(@"얼굴 없음");
}

-(void)trainFaces
{
    
    model->train(trainFaces, trainLabels);
    //trainFaces.clear();
    //trainLabels.clear();
}

-(void)predictFace:(cv::Mat&)face
{
    int predicted_label;
    double predicted_confidence;
    model->predict(face, predicted_label, predicted_confidence);
    //int prediction = model->predict(face);
    //NSLog(@"label: %d, confidence: %f, prediction: %d",predicted_label,predicted_confidence,prediction);
    dispatch_async(dispatch_get_main_queue(), ^{
        self->resultTextField.text = [NSString stringWithFormat:@"confidence: %f",predicted_confidence];
    });
    NSLog(@"confidence: %f",predicted_confidence);
}



-(void)detectFace:(cv::Mat&)image andMinNumOfDetection:(int)min
{
    faces_with_low_prob.clear();
    eyes_with_low_prob.clear();
    faces_with_high_prob.clear();
    
    face_cascade.detectMultiScale(image, faces_with_low_prob);
    if(faces_with_low_prob.empty()) return;
    
    for(auto &face:faces_with_low_prob){
        Mat croppedImg = image(face);
        eye_cascade.detectMultiScale(croppedImg, eyes_with_low_prob);
        if(eyes_with_low_prob.size()<2) continue; // 눈이 1개 이하면 얼굴이 아니라고 판단
        
        faces_with_high_prob.push_back(&face);
        if(faces_with_high_prob.size()==min)break;
    }
}
//putText(<#InputOutputArray img#>, <#const String &text#>, <#Point org#>, <#int fontFace#>, <#double fontScale#>, <#Scalar color#>)

-(void)capture
{
    captureImageView.image = videoImageView.image;
}

-(void)start
{
    [videoCamera start];
}

-(void)stop
{
    [videoCamera stop];
}
@end
