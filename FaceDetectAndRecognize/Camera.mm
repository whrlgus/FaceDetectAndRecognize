//
//  Camera.m
//  FaceDetectAndRecognize
//
//  Created by 조기현 on 23/06/2019.
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

@interface Camera()<CvVideoCameraDelegate>
@end

@implementation Camera
{
    UIViewController<CameraDelegate>* delegate;
    CvVideoCamera* videoCamera;
    CascadeClassifier faceCascade, eyeCascade;
    vector<cv::Rect> facesRect_with_low_prob,eyesRect_with_low_prob;
    cv::Rect faceRect_with_high_prob;
    cv::Mat faceMat;
    dispatch_semaphore_t semaphore;
    BOOL __block isDetectFaceRunning;
    Ptr<cv::face::LBPHFaceRecognizer> model;
    vector<cv::Mat> trainData;
    vector<int> trainLabels;
    
    processImageMode mode;
    
    int newLabel;
}


-(void)trainFace{
    trainData.clear();
    trainLabels.clear();
}

-(void)processImageNormal:(cv::Mat &)image{
    Mat image_copy;
    cvtColor(image, image_copy, COLOR_BGR2RGB);
    
    // 한개의 얼굴을 검출
    // boolean타입의 변수를 이용해서 동시에 여러번 실행하는 것을 방지
    if(!isDetectFaceRunning){
        isDetectFaceRunning=true;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self detectFace:image_copy];
            // CPU 사용량을 줄이기 위해 일정시간 쉼
            sleep(1);
            self->isDetectFaceRunning=false;
        });
    }
    
    // 프레임을 화면에 업데이트
    dispatch_async(dispatch_get_main_queue(), ^{
        // 검출된 얼굴이 있으면 사각형으로 표시
        if(!self->faceRect_with_high_prob.empty())
            rectangle(image_copy, self->faceRect_with_high_prob, Scalar(255,0,0),10);
        [self->delegate updateImageView:MatToUIImage(image_copy)];
    });
}

-(void) processImageTrain:(cv::Mat &)image{
    Mat image_copy;
    cvtColor(image, image_copy, COLOR_BGR2RGB);
    [self detectFace:image_copy];
    if(!self->faceRect_with_high_prob.empty()){
        trainData.push_back(faceMat);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->delegate captureFace:MatToUIImage(self->faceMat)];
        });
        NSLog(@"사진 수집 중... 현재 %d장",(int)trainData.size());
    }
    if(trainData.size()==50){
        mode=NORMAL;
        trainLabels.assign(trainData.size(), newLabel);
        if(newLabel==0)
            model->train(trainData, trainLabels);
        else
            model->update(trainData, trainLabels);
        ++newLabel;
        trainData.clear();
        trainLabels.clear();
        [self->delegate closePopUp];
    }
    
    
}
-(void) processImagePredict:(cv::Mat &)image{
    Mat image_copy;
    cvtColor(image, image_copy, COLOR_BGR2RGB);
    
    // 한개의 얼굴을 검출
    // boolean타입의 변수를 이용해서 동시에 여러번 실행하는 것을 방지
    if(!isDetectFaceRunning){
        isDetectFaceRunning=true;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self detectFace:image_copy];
            // CPU 사용량을 줄이기 위해 일정시간 쉼
            sleep(1);
            self->isDetectFaceRunning=false;
        });
    }
    
    // 프레임을 화면에 업데이트
    dispatch_async(dispatch_get_main_queue(), ^{
        // 검출된 얼굴이 있으면 사각형으로 표시
        if(!self->faceRect_with_high_prob.empty()){
            rectangle(image_copy, self->faceRect_with_high_prob, Scalar(255,0,0),10);
            
            int predicted_label;
            double predicted_confidence;
            //cvtColor(imageFinal, imageFinal, COLOR_RGB2GRAY);
            self->model->predict(self->faceMat, predicted_label, predicted_confidence);
            NSString* msg = [[NSString alloc] initWithFormat:@"label: %d, confidence:  %f",predicted_label,predicted_confidence];
            [self->delegate showPrecise:msg];
        }
        [self->delegate updateImageView:MatToUIImage(image_copy)];
    });
}
- (void)processImage:(cv::Mat &)image{
    switch (mode) {
        case NORMAL:
            [self processImageNormal:image];
            break;
        case TRAIN:
            [self processImageTrain:image];
            break;
        case PREDICT:
            [self processImagePredict:image];
            break;
        default:
            break;
    }
}

-(void)detectFace:(cv::Mat)image{
    facesRect_with_low_prob.clear();
    faceCascade.detectMultiScale(image, facesRect_with_low_prob);
    if(facesRect_with_low_prob.empty()){
        NSLog(@"발견된 얼굴 없음");
        return;
    }
    
    Mat croppedImage;
    cv::Rect faceRect;
    eyesRect_with_low_prob.clear();
    for(auto& face: facesRect_with_low_prob){
        croppedImage = image(face);
        eyeCascade.detectMultiScale(croppedImage, eyesRect_with_low_prob);
        if(eyesRect_with_low_prob.size()<2){
            NSLog(@"자른 얼굴 이미지에서 발견된 눈이 없음");continue;
        }
        if(!faceRect.empty()){
            NSLog(@"두개 이상의 얼굴 발견");return;
        }
        faceRect = face;
    }
    if(faceRect.empty()){
        NSLog(@"발견된 얼굴 없음");
        return;
    }
    
    NSLog(@"한개의 얼굴 검출");
    cvtColor(image(faceRect), faceMat, COLOR_RGB2GRAY);
    faceRect_with_high_prob = faceRect;
    // 사각형 표시를 지정된 시간 동안만 지속하기 위해 일정시간 이후에는 변수를 초기화
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"faceRect 초기화");
        self->faceRect_with_high_prob=cv::Rect();
    });
    
    
}

-(void)changeMode:(processImageMode)mode{
    self->mode=DEFAULT;
    sleep(1);
    self->mode=mode;
}

-(void)start{
    [videoCamera start];
}
-(void)stop{
    [videoCamera stop];
}
-(instancetype)initWithViewController:(UIViewController<CameraDelegate>*)vc{
    delegate = vc;
    [self initVideoCamera];
    [self initCascadeClassifier];
    semaphore = dispatch_semaphore_create(0);
    isDetectFaceRunning = false;
    mode = NORMAL;
    newLabel = 0;
    model = cv::face::LBPHFaceRecognizer::create();
    
    return self;
}

-(void)initVideoCamera{
    videoCamera = [[CvVideoCamera alloc] init];
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 6;
    videoCamera.delegate = self;
}

-(void)initCascadeClassifier{
    NSBundle * appBundle = [NSBundle mainBundle];
    NSString * cascadePathInBundle;
    
    cascadePathInBundle = [appBundle pathForResource: @"haarcascade_frontalface_default" ofType: @"xml"];
    string faceCascadePath([cascadePathInBundle UTF8String]);
    cascadePathInBundle = [appBundle pathForResource: @"haarcascade_eye" ofType: @"xml"];
    string eyeCascadePath([cascadePathInBundle UTF8String]);
    if (!faceCascade.load(faceCascadePath)||!eyeCascade.load(eyeCascadePath)) NSLog(@"Load error");
}
@end
