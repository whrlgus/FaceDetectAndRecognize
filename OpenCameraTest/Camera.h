//
//  Camera.h
//  OpenCameraTest
//
//  Created by 조기현 on 17/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



NS_ASSUME_NONNULL_BEGIN

@protocol CameraDelegate <NSObject>
-(void)showFrame:(UIImage*)image;
-(void)showCapturedFrame:(UIImage*)image;
@end

@interface Camera : NSObject

-(id)initWithController:(UIViewController<CameraDelegate>*)c andImageView:(UIImageView*)iv andCaptureView:(UIImageView*)cv;


-(void)start;
-(void)stop;

-(void)capture;

@end

NS_ASSUME_NONNULL_END
