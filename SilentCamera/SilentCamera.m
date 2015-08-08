//
//  SilentCamera.m
//  SilentCamera
//
//  Created by liuge on 11/27/14.
//  Copyright (c) 2014 ZiXuWuYou. All rights reserved.
//

#import "SilentCamera.h"
#import <AVFoundation/AVFoundation.h>


@interface SilentCamera () {
    AVCaptureStillImageOutput *_output;
    AVCaptureConnection *_videoConnection;
    bool _isCaptureSessionStarted;
    AVCaptureSession *session;
    AVCaptureDevice *frontCamera;
}

@end


@implementation SilentCamera

static SystemSoundID soundID = 0;

- (id)init
{
    self = [super init];
    
    if (self) {
        // Finding frontal camera
        NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        for (int i = 0; i < cameras.count; i++) {
            AVCaptureDevice *camera = cameras[i];
            
            if (camera.position == AVCaptureDevicePositionFront) {
                frontCamera = camera;
                
                [frontCamera addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:nil];
                [frontCamera addObserver:self forKeyPath:@"adjustingWhiteBalance" options:NSKeyValueObservingOptionNew context:nil];
            }
        }
    }
    return self;
}

- (id)initWithCaptureReturnBlock:(CaptureReturnBlock)captureReturnBlock {
    self = [self init];
    if (self) {
        _captureReturnBlock = captureReturnBlock;
    }
    
    return self;
}

- (void)dealloc {
    [frontCamera removeObserver:self forKeyPath:@"adjustingExposure"];
    [frontCamera removeObserver:self forKeyPath:@"adjustingWhiteBalance"];
    [_output removeObserver:self forKeyPath:@"capturingStillImage"];
    
    _videoConnection = nil;
    session = nil;
    frontCamera = nil;
    _output = nil;
}

// this will be called multiple times but normally one is enough, so _isCaptureSessionStarted is used to make this not reentrant
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"capturingStillImage"]) {
        // mute the camera. See https://gist.github.com/katokichisoft/6235b668829313d3478c/download#
        if (soundID == 0) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2" ofType:@"caf"];
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        }
        AudioServicesPlaySystemSound(soundID);
    } else if (!frontCamera.adjustingExposure && !frontCamera.adjustingWhiteBalance) {
        if (_isCaptureSessionStarted) {
            NSLock *lock = [NSLock new];
            [lock lock];
            _isCaptureSessionStarted = false;
            [lock unlock];
            
            [self captureStillImage];
        }
     }
}

- (void)takePhoto
{
    if (frontCamera != nil) {
        // Add camera to session
        session = [[AVCaptureSession alloc] init];
        
        NSError *error;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        
        if (!error && [session canAddInput:input]) {
            [session addInput:input];
            
            // Capture still image
            _output = [[AVCaptureStillImageOutput alloc] init];
            
            // Captured image settings
            [_output setOutputSettings:[[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil]];
            [_output addObserver:self forKeyPath:@"capturingStillImage" options:0 context:NULL];// mute the camera using inverted sound
            
            if ([session canAddOutput:_output]) {
                [session addOutput:_output];
                
                _videoConnection = nil;
                
                for (AVCaptureConnection *connection in _output.connections) {
                    for (AVCaptureInputPort *port in [connection inputPorts]) {
                        if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                            _videoConnection = connection;
                            break;
                        }
                    }
                    if (_videoConnection) {
                        break;
                    }
                }
                
                if (_videoConnection) {
                    [session startRunning];
                    NSLock *lock = [NSLock new];
                    [lock lock];
                    _isCaptureSessionStarted = true;
                    [lock unlock];
                }
            }
        } else {
            NSLog(@"%@",[error localizedDescription]);
        }
    }
}

- (void) captureStillImage
{
    // fix orientation bug
    if ([_videoConnection isVideoOrientationSupported])
    {
        [_videoConnection setVideoOrientation:(AVCaptureVideoOrientation)[UIDevice currentDevice].orientation];
    }
    [_output captureStillImageAsynchronouslyFromConnection:_videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if ([session isRunning]) [session stopRunning];
        
        if (imageDataSampleBuffer != NULL) {
            NSData *bitmap = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *imageCaptured = [[UIImage alloc] initWithData:bitmap];
            
            if (_captureReturnBlock) {
                _captureReturnBlock(imageCaptured);
            }
        }
    }];
}

@end
