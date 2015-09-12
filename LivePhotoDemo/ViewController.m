//
//  ViewController.m
//  LivePhotos
//
//  Created by Genady Okrain on 9/11/15.
//  Copyright © 2015 Genady Okrain. All rights reserved.
//

@import Photos;
@import PhotosUI;
@import MobileCoreServices;
#import "ViewController.h"

@interface DummyLivePhotoViewSubclass : PHLivePhotoView
@end
@implementation DummyLivePhotoViewSubclass
@end

@interface ViewController () <PHLivePhotoViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet PHLivePhotoView *livePhotoView;
@property (strong, nonatomic) PHLivePhoto *livePhoto;
@property (strong, nonatomic) NSURL *videoURL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.videoURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"m4v"];
    self.livePhotoView.delegate = self;
    [self load];
}

- (void)load {
    AVURLAsset *asset = [AVURLAsset assetWithURL:self.videoURL];
    // Get an image
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, asset.duration.timescale)]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        // Save the image
        NSData *imageData = UIImagePNGRepresentation([UIImage imageWithCGImage:image]);
        NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory: NSDocumentDirectory inDomains: NSUserDomainMask];
        NSURL *photoURL = [urls[0] URLByAppendingPathComponent:@"image.jpg"];
        [[NSFileManager defaultManager] removeItemAtURL:photoURL error:nil];
        [imageData writeToURL:photoURL atomically:YES];

        NSURL *videoURL = self.videoURL;

        // Call private API to create the live photo
//        self.livePhotoView.livePhoto = nil;
        self.livePhoto = nil;
        self.livePhoto = [[PHLivePhoto alloc] init];
        SEL initWithImageURLvideoURL = NSSelectorFromString(@"_initWithImageURL:videoURL:");
        if ([self.livePhoto respondsToSelector:initWithImageURLvideoURL]) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.livePhoto methodSignatureForSelector:initWithImageURLvideoURL]];
            [invocation setSelector:initWithImageURLvideoURL];
            [invocation setTarget:self.livePhoto];
            [invocation setArgument:&(photoURL) atIndex:2];
            [invocation setArgument:&(videoURL) atIndex:3];
            [invocation invoke];
        }

        // Set the live photo
        self.livePhotoView.livePhoto = self.livePhoto;
    }];
}

- (IBAction)takePhoto:(UIBarButtonItem *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.videoURL = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self load];
    }];
}

#pragma mark - PHLivePhotoViewDelegate

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"willBeginPlaybackWithStyle");
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"didEndPlaybackWithStyle");
}

@end
