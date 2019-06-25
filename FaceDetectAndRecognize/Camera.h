//
//  Camera.h
//  FaceDetectAndRecognize
//
//  Created by 조기현 on 23/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum processImageMode
{
    TRAIN,
    PREDICT,
    NORMAL,
    DEFAULT
} ProcessImageMode;

@protocol CameraDelegate <NSObject>

-(void)updateImageView:(UIImage*)image;
-(void)showPrecise:(NSString*)msg;
-(void)captureFace:(UIImage*)face;
-(void)closePopUp;
@end

@interface Camera : NSObject

-(instancetype)initWithViewController:(UIViewController<CameraDelegate>*)vc;
-(void)start;
-(void)stop;
-(void)trainFace;
-(void)predictFace;
-(void)changeMode:(ProcessImageMode)mode;
@end

NS_ASSUME_NONNULL_END
