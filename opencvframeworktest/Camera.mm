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
    UIViewController<CameraDelegate>* viewController;
    UIImageView* videoImageView;
    UITextField* resultTextField;
    CvVideoCamera* videoCamera;
    CascadeClassifier face_cascade, eye_cascade;
    vector<cv::Rect> facesRect_with_low_prob,eyesRect_with_low_prob;
    cv::Rect faceRect_with_high_prob;
    
    cv::Rect faceFinal;
    Mat imageFinal;
    
    Mat faceMat;
    
    bool isDetectedOne;
    
    
    BOOL __block isFaceDetectRunning;
    BOOL __block isTrainRunning;
    BOOL __block isPredictRunning;
    dispatch_semaphore_t semaphore;
    
    
    
    Ptr<cv::face::LBPHFaceRecognizer> model;
    vector<cv::Mat> trainFaces;
    vector<int> trainLabels;
    
    int newLabel;
    
    bool isTrained;
    
    
    Mat* imageForThread;
    
    
    
}

-(instancetype)initWithViewController:(UIViewController<CameraDelegate>*)vc andVideoImageView:(UIImageView*)viv andResultTextField:(UITextField*)rtf andNewLable:(int*)nl
{
    viewController = vc;
    videoImageView = viv;
    resultTextField = rtf;
    newLabel = 0;
    [self initCamera];
    [self initCascadeClassifier];
    model = cv::face::LBPHFaceRecognizer::create();
    //trainFaces.clear();
    //trainLabels.clear();
    isTrained=false;
    isFaceDetectRunning = false;
    isTrainRunning = false;
    isPredictRunning = false;
    semaphore = dispatch_semaphore_create(0);
    
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
    if(!isFaceDetectRunning){
        //detectface 실행
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            self->isFaceDetectRunning=true;
            NSLog(@"global dispatch 시작");
            
            Mat i = image;
            
            if((self->isDetectedOne = [self detectFace:i])){
                if(self.trainBtnClicked){
                    dispatch_semaphore_signal(self->semaphore);
                }
                if(self.predictBtnClicked){
                    NSLog(@"predict 시작");
                    dispatch_semaphore_signal(self->semaphore);
                    [self predictFace];
                    
                }
            }
            
            self->isFaceDetectRunning=false;
        });
    }
    
    
    // ui 업데이트를 위한 메인 큐
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"메인 큐 실행 ui update");
        
        cvtColor(image, image, COLOR_BGRA2RGB);
        //cvtColor(image, self->faceMat,COLOR_RGB2GRAY);
        if(self->isDetectedOne){
            NSLog(@"메인 큐 실행 얼굴 표시");
            
            rectangle(image, self->faceRect_with_high_prob, Scalar(255,0,0),10);
            NSLog(@"사각형");
        }
        self->videoImageView.image = MatToUIImage(image);
        self->faceRect_with_high_prob = cv::Rect();
    });
    
    
    //[viewController updateImageView:MatToUIImage(image)];
    
    
    
}

-(void)prepareTrainData
{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    Mat faceMat_copy=faceMat;
    
    trainFaces.push_back(imageFinal);
    NSLog(@"%d label num: %d",(int)self->trainFaces.size(),newLabel);
    dispatch_async(dispatch_get_main_queue(), ^{
        self->resultTextField.text = [NSString stringWithFormat:@"사진 수집 중 %d%%",(int)self->trainFaces.size()*2];
    });
    
}

-(void)trainFaces
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        while(self->trainFaces.size()<50)
            [self prepareTrainData];
        
        self->trainLabels.assign(self->trainFaces.size(), self->newLabel);
        
        
        if(self->newLabel==0)
            self->model->train(self->trainFaces, self->trainLabels);
        else
            self->model->update(self->trainFaces, self->trainLabels);
        vector<Mat>().swap(self->trainFaces);
        vector<int>().swap(self->trainLabels);
        NSLog(@"train 끝@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        self->newLabel=self->newLabel+1;
        [self->viewController enableRecognizeButton];
        
    });
}

-(void)predictFace
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        dispatch_semaphore_wait(self->semaphore, DISPATCH_TIME_FOREVER);
        Mat faceMat_copy = self->faceMat;
        
        int predicted_label;
        double predicted_confidence;
        //cvtColor(imageFinal, imageFinal, COLOR_RGB2GRAY);
        self->model->predict(self->imageFinal, predicted_label, predicted_confidence);
        
        int prediction = self->model->predict(self->imageFinal);
        //NSLog(@"label: %d, confidence: %f, prediction: %d",predicted_label,predicted_confidence,prediction);
        dispatch_async(dispatch_get_main_queue(), ^{
            self->resultTextField.text = [NSString stringWithFormat:@"confidence: %f///prediction: %d ",predicted_confidence,prediction];
        });
    });
}



-(bool)detectFace:(cv::Mat&)image
{
    vector<cv::Rect>().swap(facesRect_with_low_prob);
    //facesRect_with_low_prob.clear();
    
    Mat tmp = image;
    
    
    face_cascade.detectMultiScale(tmp, facesRect_with_low_prob);
    if(facesRect_with_low_prob.empty()) return false;
    
    //eyesRect_with_low_prob.clear();
    vector<cv::Rect>().swap(eyesRect_with_low_prob);
    for(auto& face: facesRect_with_low_prob){
        if(!faceRect_with_high_prob.empty()) return false;
        
        Mat croppedImg = tmp(face);
        eye_cascade.detectMultiScale(croppedImg, eyesRect_with_low_prob);
        if(eyesRect_with_low_prob.size()<2) continue; // 눈이 1개 이하면 얼굴이 아니라고 판단
        faceRect_with_high_prob = face;
        cvtColor(croppedImg, imageFinal, COLOR_RGB2GRAY);
        faceFinal = face;
        return true;
    }
    return true;
}

//putText(<#InputOutputArray img#>, <#const String &text#>, <#Point org#>, <#int fontFace#>, <#double fontScale#>, <#Scalar color#>)



-(void)start
{
    [videoCamera start];
}

-(void)stop
{
    [videoCamera stop];
}
@end
