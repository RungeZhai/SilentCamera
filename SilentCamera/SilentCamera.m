//
//  SilentCamera.m
//  SilentCamera
//
//  Created by liuge on 11/27/14.
//  Copyright (c) 2014 iLegendSoft. All rights reserved.
//

#import "SilentCamera.h"
#import <UIKit/UIKit.h>


@interface SilentCamera () {
    AVCaptureStillImageOutput *_output;
    AVCaptureConnection *_videoConnection;
    bool _isCaptureSessionStarted;
    AVCaptureSession *session;
    AVCaptureDevice *frontCamera;
//    AVAudioPlayer *invertedSound;
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
//    [_output removeObserver:self forKeyPath:@"capturingStillImage"];
    
    _videoConnection = nil;
    session = nil;
    frontCamera = nil;
    _output = nil;
}

// this will be called multiple times but normally one is enough, so _isCaptureSessionStarted is used to make this not reentrant
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
     if (!frontCamera.adjustingExposure && !frontCamera.adjustingWhiteBalance) {
        if (_isCaptureSessionStarted) {
            NSLock *lock = [NSLock new];
            [lock lock];
            _isCaptureSessionStarted = false;
            [lock unlock];
            
            [self captureStillImage];
        }
     } else if ([keyPath isEqualToString:@"capturingStillImage"]) {
//         if (!invertedSound.isPlaying) {
//             [invertedSound play];
//         }
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
//            [self becomeSilentModeForCaptureOutput:_output];
            
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
    if (soundID == 0) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2" ofType:@"caf"];
        NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    }
    AudioServicesPlaySystemSound(soundID);
    
    
    // fix orientation bug
    if ([_videoConnection isVideoOrientationSupported])
    {
        [_videoConnection setVideoOrientation:(AVCaptureVideoOrientation)[UIDevice currentDevice].orientation];
    }
    [_output captureStillImageAsynchronouslyFromConnection:_videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if ([session isRunning]) [session stopRunning];
//        if ([invertedSound isPlaying]) [invertedSound stop];
        
        if (imageDataSampleBuffer != NULL) {
            NSData *bitmap = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *imageCaptured = [[UIImage alloc] initWithData:bitmap];
            
            if (_captureReturnBlock) {
                _captureReturnBlock(imageCaptured);
            }
        }
    }];
}


/* 
 See https://gist.github.com/katokichisoft/6235b668829313d3478c/download#
 
 this method is not working all right, may be the caf file is not right.
 I didn't delete the related lines code, just commented them. So if you want to test this. 
 Besides uncommenting this method, everything about invertedSound should be uncommented.
*/

//- (void)becomeSilentModeForCaptureOutput:(AVCaptureStillImageOutput *)imageOutput
//{
//    if (!invertedSound) {
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2"
//                                                         ofType:@"caf"];
//        NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
//        invertedSound = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
//                                                                    error:NULL];
//        [invertedSound prepareToPlay];
//        
//        [imageOutput addObserver:self
//                      forKeyPath:@"capturingStillImage"
//                         options:0 context:NULL];
//    }
//}

@end
