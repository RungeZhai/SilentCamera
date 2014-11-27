//
//  SilentCamera.h
//  SilentCamera
//
//  Created by liuge on 11/27/14.
//  Copyright (c) 2014 iLegendSoft. All rights reserved.
//  Code from http://stackoverflow.com/questions/18736189/capture-images-in-the-background
//  http://stackoverflow.com/questions/3662930/iphone-avfoundation-camera-orientation
//  http://stackoverflow.com/questions/3662930/iphone-avfoundation-camera-orientation
//  https://gist.github.com/katokichisoft/6235b668829313d3478c/download#
//  http://www.raywenderlich.com/69369/audio-tutorial-ios-playing-audio-programatically-2014-edition
//  http://stackoverflow.com/questions/14690484/why-avcapturestillimageoutput-capturestillimageasynchronouslyfromconnectionco
//  http://stackoverflow.com/questions/10053197/how-to-capture-image-without-displaying-preview-in-ios/10160104#10160104
//  https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html#//apple_ref/doc/uid/TP40010188-CH5-SW30
//  http://www.musicalgeometry.com/?p=1297
//  http://stackoverflow.com/questions/10115716/avfoundation-capture-uiimage
//  http://stackoverflow.com/questions/4401232/avfoundation-how-to-turn-off-the-shutter-sound-when-capturestillimageasynchrono
//  NO License, Use at your own risk
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^CaptureReturnBlock)(UIImage *image);



@interface SilentCamera : NSObject

@property (strong, nonatomic) CaptureReturnBlock captureReturnBlock;

- (id)initWithCaptureReturnBlock:(CaptureReturnBlock)captureReturnBlock;

- (void)takePhoto;

@end
