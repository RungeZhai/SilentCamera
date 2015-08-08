//
//  QuietCamera.m
//  SilentCamera
//
//  Created by liuge on 7/1/15.
//  Copyright (c) 2015 ZiXuWuYou. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "QuietCamera.h"

@interface QuietCamera () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    NSInteger _frameCount;
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
    //    [_device lockForConfiguration:nil];
    //    _device.activeVideoMinFrameDuration = CMTimeMake(1, 5);
    //    _device.activeVideoMaxFrameDuration = CMTimeMake(1, 5);
    //    [_device unlockForConfiguration];
    
    // Create the capture input
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (!captureInput) return;
    
    // Create capture output
    // Update thanks to Jake Marsh who points out not to use the main queue
    char *queueName = "com.ZiXuWuYou.tasks.grabFrames";
    dispatch_queue_t queue = dispatch_queue_create(queueName, NULL);
    
    
    // GeLiu_TODO: see http://www.phonesdevelopers.com/1713873/
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *newSettings =
    @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    captureOutput.videoSettings = newSettings;
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    [captureOutput setSampleBufferDelegate:self queue:queue];
    
    // Create a session
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    if ([_session canAddInput:captureInput]) [_session addInput:captureInput];
    if ([_session canAddOutput:captureOutput]) [_session addOutput:captureOutput];
    [_session commitConfiguration];
}

- (void)takePhoto {
    [self configCaptureSession];
    [_session startRunning];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    /**
     * 第一个buffer进来的时候, _device的adjustingWhiteBalance等都还没来得及调整
     * 所以, 判断这些属性是无效的, 解决方法是跳过前几个buffer再判断,
     * 还有一个问题是adjustingExposure属性要等好长时间(3-9秒不等)才调整完
     * 我们等不了那么长时间, 所以没有判断该属性, 只判断了whiteBalance
     * 事实证明效果还可以, 时间控制在三秒内, 这是个折衷方案
     */
    if ((++_frameCount < 3) || (_device.isAdjustingWhiteBalance)) {
        return;
    }
    
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
