//
//  ActivityManagerService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/25/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "ActivityManagerService.h"
#import <UIKit/UIKit.h>

@interface ActivityManagerService()

@property (nonatomic, assign) int activityCount;

@end

@implementation ActivityManagerService

+ (ActivityManagerService *)shared
{
    static id retval;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        retval = [[ActivityManagerService alloc] init];
    });
    return retval;
}

-(void)incrementActivityCount
{
    self.activityCount += 1;
    
    if(self.activityCount == 1)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLoadingScreen];
            [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:YES];
            [UIApplication.sharedApplication beginIgnoringInteractionEvents];
        });
    }
}

-(void)decrementActivityCount
{
    if (self.activityCount > 0)
    {
        self.activityCount -= 1;
    
        if(self.activityCount == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissLoadingScreen];
                [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
                [UIApplication.sharedApplication endIgnoringInteractionEvents];
            });

        }
    }
}

-(void)dismissLoadingScreen
{
    if(UIApplication.sharedApplication.keyWindow)
        for(UIView *view in UIApplication.sharedApplication.keyWindow.subviews)
            if(view.tag == 9999)
                [view removeFromSuperview];
}

-(void)showLoadingScreen
{
    if (UIApplication.sharedApplication.keyWindow)
    {
        UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
        [view setTag:9999];
        [view setBackgroundColor:[UIColor blackColor]];
        [view setAlpha:0.5];
        [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
        [UIApplication.sharedApplication.keyWindow addSubview:view];
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [activity setCenter:view.center];
        [view addSubview:activity];
        [activity startAnimating];
        [activity setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    }
}


@end

//    fileprivate func showLoadingScreen(isVisible: Bool = true)
//    {
//        UIApplication.shared.beginIgnoringInteractionEvents()
//        
//        let screenRect : CGRect = UIScreen.main.bounds
//        let loadingScreen : UIView = UIView(frame: screenRect)
//        loadingScreen.tag = 9999
//        loadingScreen.backgroundColor = UIColor.black
//        loadingScreen.alpha = isVisible ? 0.5 : 0.0
//        loadingScreen.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
//        
//        UIApplication.shared.keyWindow?.addSubview(loadingScreen)
//        
//        if isVisible
//        {
//            let activity : UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
//            activity.center = loadingScreen.center
//            loadingScreen.addSubview(activity)
//            activity.startAnimating()
//            activity.autoresizingMask = [UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
//        }
//    }
//    
//    }
