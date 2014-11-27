SilentCamera
============

Take photo in the background without showing preview.



Usage:

    // initialize SilentCamera with a return block

    SilentCamera *silentCamera = [[SilentCamera alloc] initWithCaptureReturnBlock:^(UIImage *image) {
    
        ... // Do whatever you want with the image captured.
    
    }];
    
    [slientCamera takePhoto];


The above is just a specification. As a matter of fact, silentCamera should not be a local variable as it should not be released after the call of takePhoto. Method takePhoto is async, that's why a block is needed.

![Alt][screenshot1_thumb]

[screenshot1_thumb]: https://cloud.githubusercontent.com/assets/3366713/5217069/f991edea-7676-11e4-8360-17ea56a61f42.jpg
