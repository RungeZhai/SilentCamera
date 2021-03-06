//
//  ViewController.m
//  SilentCamera
//
//  Created by liuge on 11/27/14.
//  Copyright (c) 2014 ZiXuWuYou. All rights reserved.
//

#import "ViewController.h"
#import "SilentCamera.h"
#import "QuietCamera.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) SilentCamera *silentCamera;
@property (strong, nonatomic) QuietCamera *quietCamera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)captureImage:(id)sender {

//    _silentCamera = [[SilentCamera alloc] initWithCaptureReturnBlock:^(UIImage *image) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _imageView.image = image;   // imageView is already a weak reference
//            _silentCamera = nil;        // release it
//        });
//    }];
//    
//    [_silentCamera takePhoto];
    
    _quietCamera = [[QuietCamera alloc] initWithCamera:kCameraBack captureReturnBlock:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _imageView.image = image;
            _silentCamera = nil;
        });
    }];
    
    [_quietCamera takePhoto];
}


@end
