SilentCamera
============

Take photo in the background without showing preview.



Usage:

// initialize SilentCamera with a return block

SilentCamera *silentCamera = [[SilentCamera alloc] initWithCaptureReturnBlock:^(UIImage *image) {

    dispatch_async(dispatch_get_main_queue(), ^{

        ... // Do whatever you want with the image captured.

    });

}];

[slientCamera takePhoto];




![Alt][screenshot1_thumb]

[screenshot1_thumb]: https://cloud.githubusercontent.com/assets/3366713/5217069/f991edea-7676-11e4-8360-17ea56a61f42.jpg
