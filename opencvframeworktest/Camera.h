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

@interface Camera : NSObject
-(instancetype)initWithController:(UIViewController*)c andVideoImageView:(UIImageView*)viv andCaptureImageView:(UIImageView*)civ andResultTextField:(UITextField*)rtf;
-(void)start;
-(void)stop;
-(void)capture;
@end

NS_ASSUME_NONNULL_END
