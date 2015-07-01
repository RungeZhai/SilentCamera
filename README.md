SilentCamera
============

Take photo in the background without showing preview.



Usage:
There are 2 kind of implementations.

Implementation 1:

    // initialize SilentCamera with a return block

    _silentCamera = [[SilentCamera alloc] initWithCaptureReturnBlock:^(UIImage *image) {
    
        ... // Do whatever you want with the image captured.
        _silentCamera = nil;
    
    }];
    
    [_slientCamera takePhoto];

Implementation 2:

    // initialize SilentCamera with a return block

    _quietCamera = [[QuietCamera alloc] initWithCamera:kCameraBack captureReturnBlock:^(UIImage *image) {

        ... // Do whatever you want with the image captured.
        _quietCamera = nil;

    }];

    [_quietCamera takePhoto];
    

Implementation 2 is absolutely no sound at all.

![Alt][screenshot1_thumb]

[screenshot1_thumb]: https://cloud.githubusercontent.com/assets/3366713/5217069/f991edea-7676-11e4-8360-17ea56a61f42.jpg
