#import "ImageCorrection.h"
#import <UIKit/UIKit.h>

@implementation ImageCorrection


- (instancetype)init {
    if (!(self = [super init])) return nil;

    self.correctionDictionary = [[NSMutableDictionary<NSString *,NSString *> alloc]
                                 initWithDictionary:@{kRollMax:@""
                                  ,kRollMin:@""
                                  ,kPitchMax:@""
                                  ,kPitchMin:@""
                                  ,kYawMax:@""
                                  ,kYawMin:@""
                                  ,kDeviceTooFar:@""
                                  ,kDeviceTooClose:@""
                                  ,kCentered:@""
                                  ,kFocusing:@""
                                  ,kAdjustingExposure:@""
                                  ,kAdjustingColorBalance:@""
                                                      }];
    
    [self.correctionDictionary addObserver:self forKeyPath:kRollMax options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kRollMin options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kPitchMax options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kPitchMin options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kYawMax options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kYawMin options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kDeviceTooFar options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kDeviceTooClose options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kCentered options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kFocusing options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kAdjustingExposure options:NSKeyValueObservingOptionOld context:nil];
    [self.correctionDictionary addObserver:self forKeyPath:kAdjustingColorBalance options:NSKeyValueObservingOptionOld context:nil];

    return self;
}

-(void)dealloc
{
    NSLog(@"%@", @"ImageCorrection Dealloc");
        
    [self.correctionDictionary removeObserver:self forKeyPath:kRollMax];
    [self.correctionDictionary removeObserver:self forKeyPath:kRollMin];
    [self.correctionDictionary removeObserver:self forKeyPath:kPitchMax];
    [self.correctionDictionary removeObserver:self forKeyPath:kPitchMin];
    [self.correctionDictionary removeObserver:self forKeyPath:kYawMax];
    [self.correctionDictionary removeObserver:self forKeyPath:kYawMin];
    [self.correctionDictionary removeObserver:self forKeyPath:kDeviceTooFar];
    [self.correctionDictionary removeObserver:self forKeyPath:kDeviceTooClose];
    [self.correctionDictionary removeObserver:self forKeyPath:kCentered];
    [self.correctionDictionary removeObserver:self forKeyPath:kFocusing];
    [self.correctionDictionary removeObserver:self forKeyPath:kAdjustingExposure];
    [self.correctionDictionary removeObserver:self forKeyPath:kAdjustingColorBalance];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(correctionDictionaryChanged)])
        [self.delegate correctionDictionaryChanged];
}

-(NSArray*)messages
{
    NSMutableArray<NSString*> *array = [NSMutableArray<NSString*> new];
    
    for(NSString *key in self.correctionDictionary.allKeys)
    {
        NSString *value = [self.correctionDictionary valueForKey:key];
        
        if(value.length > 0)
            [array addObject:value];
    }
    
    return [NSArray arrayWithArray:array];
}

-(NSDictionary<NSString*,NSNumber*>*)settingsForID
{
    return @{
             kPitchMax:[NSNumber numberWithDouble:0.1]
             ,kPitchMin:[NSNumber numberWithDouble:-0.1]
             ,kRollMax:[NSNumber numberWithDouble:0.1]
             ,kRollMin:[NSNumber numberWithDouble:-0.1]
             ,kAlignmentMargin: [NSNumber numberWithFloat:UIScreen.mainScreen.bounds.size.width*0.1]
             };
}

-(double)idSettingForKey:(NSString *)key
{
    double value = 0;
    
    if ([self.settingsForID objectForKey:key])
        value = [self.settingsForID objectForKey:key].doubleValue;
    
    return value;
}


@end

