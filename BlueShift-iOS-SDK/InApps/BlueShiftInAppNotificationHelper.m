//
//  BlueShiftInAppNotificationHelper.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "../BlueShift.h"

static NSDictionary *_inAppTypeDictionay;

@implementation BlueShiftInAppNotificationHelper

+ (void)load {
    _inAppTypeDictionay = @{
                        kInAppNotificationModalHTMLKey: @(BlueShiftInAppTypeHTML),
                        kInAppNotificationTypeCenterPopUpKey: @(BlueShiftInAppTypeModal),
                        kInAppNotificationTypeSlideBannerKey: @(BlueShiftNotificationSlideBanner),
                        kInAppNotificationTypeRatingKey: @(BlueShiftNotificationRating)
                    };
}

+ (BlueShiftInAppType)inAppTypeFromString:(NSString*)inAppType {
    NSNumber *_inAppType = inAppType != nil ? _inAppTypeDictionay[inAppType] : @(BlueShiftInAppDefault);
    return [_inAppType integerValue];
}

+ (NSString *)getLocalDirectory:(NSString *) fileName {
    NSString* tempPath = NSTemporaryDirectory();
    return [tempPath stringByAppendingPathComponent: fileName];
}

+ (BOOL)hasFileExist:(NSString *) fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath: [self getLocalDirectory: fileName]];
}

+ (NSString *)createFileNameFromURL:(NSString *) imageURL {
    NSString *fileName = [[imageURL lastPathComponent] stringByDeletingPathExtension];
    NSURL *url = [NSURL URLWithString: imageURL];
    NSString *extension = [url pathExtension];
    fileName = [fileName stringByAppendingString:@"."];
    return [fileName stringByAppendingString: extension];
}

+ (BOOL)hasDigits:(NSString *) digits {
    NSCharacterSet *notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return ([digits rangeOfCharacterFromSet: notDigits].location == NSNotFound);
}

+ (void)deleteFileFromLocal:(NSString *) fileName {
    NSString *filePath = [self getLocalDirectory: fileName];
    if ([self hasFileExist: fileName]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
}

+ (CGFloat)convertPointsHeightToPercentage:(float) height forWindow:(UIWindow*)window {
    CGFloat presentationAreaHeight = [self getPresentationAreaHeightForWindow:window];
    CGFloat heightInPercentage = (CGFloat) (((height/presentationAreaHeight) * 100.0f));
    return heightInPercentage;
}

+ (CGFloat)convertPointsWidthToPercentage:(float) width forWindow:(UIWindow*)window {
    CGFloat presentationAreaWidth = [self getPresentationAreaWidthForWindow:window];
    CGFloat widthInPercentage = (CGFloat) (((width/presentationAreaWidth) * 100.0f));
    return  widthInPercentage;
}

+ (CGFloat)convertPercentageHeightToPoints:(float) height forWindow:(UIWindow*)window {
    CGFloat presentationAreaHeight = [self getPresentationAreaHeightForWindow:window];
    CGFloat heightInPoints = (CGFloat) ceil(presentationAreaHeight * (height / 100.0f));
    return heightInPoints;
}

+ (CGFloat)convertPercentageWidthToPoints:(float) width forWindow:(UIWindow*)window {
    CGFloat presentationAreaWidth = [self getPresentationAreaWidthForWindow:window];
    CGFloat widthInPoints = (CGFloat) ceil(presentationAreaWidth * (width / 100.0f));
    return widthInPoints;
}

+ (CGFloat)getPresentationAreaHeightForWindow:(UIWindow*)window {
    CGFloat topMargin = 0.0;
    CGFloat bottomMargin = 0.0;
    if (@available(iOS 11.0, *)) {
        topMargin =  window.safeAreaInsets.top;
        bottomMargin = window.safeAreaInsets.bottom;
    } else {
        topMargin = [[UIApplication sharedApplication] statusBarFrame].size.height;
        bottomMargin = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    CGFloat presentationAreaHeight = window.bounds.size.height - topMargin - bottomMargin;
    return presentationAreaHeight;
}

+ (CGFloat)getPresentationAreaWidthForWindow:(UIWindow*)window {
    CGFloat leftMargin = 0.0;
    CGFloat rightMargin = 0.0;
    if (@available(iOS 11.0, *)) {
        leftMargin = window.safeAreaInsets.left;
        rightMargin = window.safeAreaInsets.right;
    }
    CGFloat presentationAreaWidth = window.bounds.size.width - leftMargin - rightMargin;
    return presentationAreaWidth;
}

+ (UIWindow *)getApplicationKeyWindow {
    if (@available(iOS 13.0, *)) {
        if ([[BlueShift sharedInstance]config].isSceneDelegateConfiguration == YES) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

+ (BOOL)checkAppDelegateWindowPresent {
    if (![[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        return NO;
    }
    return YES;
}

+ (NSString*)getEncodedURLString:(NSString*) urlString {
    if (urlString && ![urlString isEqualToString:@""]) {
        NSString *charactersToEscape = @"!*'();:@&=+$,/?%#[]<>^`\{|}"" ";
        NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
        NSString *escapedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        return escapedURLString;
    }
    return urlString;
}

+ (BOOL)isIpadDevice {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

@end
