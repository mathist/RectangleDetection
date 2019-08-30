//
//  TextReadingViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 8/30/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "TextReadingViewController.h"
#import "TextReadingService.h"

@interface TextReadingViewController () <TextReadingServiceDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imgView;
@property (nonatomic, weak) IBOutlet UITextView *txtView;
@property (nonatomic, strong) UIImage *img;

@property (nonatomic, retain) TextReadingService *textReadingService;

@end

@implementation TextReadingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textReadingService = [TextReadingService new];
    [self.textReadingService setDelegate:self];
}

-(IBAction)takePhoto:(UIButton *)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    [self presentViewController:picker animated:YES completion:nil];
}

-(IBAction)readText:(UIButton *)sender
{
    if (self.img)
        [self.textReadingService readText:self.img];
}

#pragma mark TextReadingServiceDelegate methods

//- (void)textFound:(nonnull NSArray<VNRecognizedTextObservation *> *)texts
//{
//    NSMutableArray<NSString*> *strings = [NSMutableArray<NSString*> new];
//    
//    for (VNRecognizedTextObservation *observation in texts)
//    {
//        VNRecognizedText *text = [[observation topCandidates:1] firstObject];
//        
//        if(text)
//        {
//            [strings addObject:text.string];
//        }
//    }
//
//  dispatch_async(dispatch_get_main_queue(), ^{
//    [self.txtView setText: [strings componentsJoinedByString:@"\n"]];
//  });
//}

#pragma mark UIImagePickerControllerDelegate methods

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.presentedViewController)
        [self dismissViewControllerAnimated:true completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    if(info[UIImagePickerControllerEditedImage])
        self.img = info[UIImagePickerControllerEditedImage];
    else if (info[UIImagePickerControllerOriginalImage])
        self.img = info[UIImagePickerControllerOriginalImage];
    
    if(self.img)
        self.imgView.image = self.img;
    
    if (self.presentedViewController)
        [self dismissViewControllerAnimated:true completion:nil];
}

@end
