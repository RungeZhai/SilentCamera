//
//  QuietCamera.h
//  SilentCamera
//
//  Created by liuge on 7/1/15.
//  Copyright (c) 2015 ZiXuWuYou. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    kCameraFront,
    kCameraBack,
};

typedef void(^ResultBlock)(UIImage *image);


@interface QuietCamera : NSObject

@property (copy, nonatomic) ResultBlock captureReturnBlock;
@property (nonatomic) int camera;   // 0: front; 1: back

- (id)initWithCamera:(int)camera captureReturnBlock:(ResultBlock)captureReturnBlock;

- (void)takePhoto;

@end
