//
//  QuietCamera.m
//  SilentCamera
//
//  Created by liuge on 7/1/15.
//  Copyright (c) 2015 iLegendSoft. All rights reserved.
//

#import "QuietCamera.h"
#import <AVFoundation/AVFoundation.h>

@interface QuietCamera () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
}

@end


@implementation QuietCamera

- (id)initWithCamera:(int)camera captureReturnBlock:(ResultBlock)captureReturnBlock {
    self = [self init];
    if (self) {
        _captureReturnBlock = captureReturnBlock;
        _camera = camera;
    }
    
    return self;
}

- (void)dealloc {
    [_session stopRunning];
    _session = nil;
    _device = nil;
}

- (void)configCaptureSession {
    // Is a camera available
    if ([AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count == 0) return;
    
    // Retrieve the selected camera
    _device = (_camera == kCameraFront) ? [[self class] frontCamera] : [[self class] backCamera];
    
    // Create the capture input
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (!captureInput) return;
    
    // Create capture output
    // Update thanks to Jake Marsh who points out not to use the main queue
    char *queueName = "com.ZiXuWuYou.tasks.grabFrames";
    dispatch_queue_t queue = dispatch_queue_create(queueName, NULL);
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    [captureOutput setSampleBufferDelegate:self queue:queue];
    
    // Create a session
    _session = [[AVCaptureSession alloc] init];
    if ([_session canAddInput:captureInput]) [_session addInput:captureInput];
    if ([_session canAddOutput:captureOutput]) [_session addOutput:captureOutput];
}

- (void)takePhoto {
    [self configCaptureSession];
    [_session startRunning];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (_device.isAdjustingExposure || _device.isAdjustingWhiteBalance) return;
    
    [_session stopRunning];
    for(AVCaptureInput *input in _session.inputs) {
        [_session removeInput:input];
    }
    
    for(AVCaptureOutput *output in _session.outputs) {
        [_session removeOutput:output];
    }
    
    @autoreleasepool
    {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer options:(__bridge_transfer NSDictionary *)attachments];
        
        UIImage *image = nil;
        if (ciImage) {
            CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:ciImage fromRect:ciImage.extent];
            image = [UIImage imageWithCGImage:cgImage
                                        scale:[UIScreen mainScreen].scale
                                  orientation:[[self class] currentImageOrientation:_camera == 0]];
        }
        
        if (_captureReturnBlock) _captureReturnBlock(image);
    }
}


+ (AVCaptureDevice *)backCamera
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices)
        if (device.position == AVCaptureDevicePositionBack) return device;
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

+ (AVCaptureDevice *)frontCamera
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices)
        if (device.position == AVCaptureDevicePositionFront) return device;
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

+ (UIImageOrientation)currentImageOrientation:(BOOL)isUsingFrontCamera
{
    switch ([UIDevice currentDevice].orientation)
    {
        case UIDeviceOrientationPortrait:
            return isUsingFrontCamera ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
        case UIDeviceOrientationPortraitUpsideDown:
            return isUsingFrontCamera ? UIImageOrientationRightMirrored :UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeLeft:
            return isUsingFrontCamera ? UIImageOrientationDownMirrored :  UIImageOrientationUp;
        case UIDeviceOrientationLandscapeRight:
            return isUsingFrontCamera ? UIImageOrientationUpMirrored :UIImageOrientationDown;
        default:
            return  UIImageOrientationUp;
    }
}

@end
