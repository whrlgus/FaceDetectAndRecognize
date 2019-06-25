//
//  Camera.h
//  opencvframeworktest
//
//  Created by 조기현 on 19/06/2019.
//  Copyright © 2019 none. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CameraDelegate <NSObject>

-(void)updateImageView:(UIImage*)image;
-(void)enableRecognizeButton;

@end


@interface Camera : NSObject

@property (nonatomic, assign) BOOL trainBtnClicked;
@property (nonatomic, assign) BOOL predictBtnClicked;

-(instancetype)initWithViewController:(UIViewController<CameraDelegate>*)vc andVideoImageView:(UIImageView*)viv andResultTextField:(UITextField*)rtf andNewLable:(int*)nl;
-(void)trainFaces;
-(void)predictFace;
-(void)start;
-(void)stop;

@end


NS_ASSUME_NONNULL_END
