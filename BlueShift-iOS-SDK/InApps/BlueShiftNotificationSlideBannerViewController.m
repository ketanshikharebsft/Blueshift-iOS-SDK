//
//  BlueShiftNotificationSlideBannerViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 23/07/19.
//

#define kSlideToLeftMultiplier -2.0
#define kSlideToRightMultiplier 2.0

#import "BlueShiftNotificationSlideBannerViewController.h"
#import "BlueShiftNotificationView.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotificationDelegate.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "../BlueshiftConstants.h"

@interface BlueShiftNotificationSlideBannerViewController ()<UIGestureRecognizerDelegate> {
    UIView *slideBannerView;
    UIView *bottomSafeAreaView;
}

@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;
@end

@implementation BlueShiftNotificationSlideBannerViewController

- (void)loadView {
   if (self.canTouchesPassThroughWindow) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
    
    slideBannerView = [self createNotificationWindow];
    [self enableSingleTap];
    if (!self.canTouchesPassThroughWindow) {
        [self setTapGestureForView];
    }
    [self setSwipeGestureForBannerView];
    [self presentAnimationView];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    for (UIView *view in [slideBannerView subviews])
    {
        [view removeFromSuperview];
    }
    [self configureBackground];
    [self createNotificationView];
    [self initializeNotificationView];
}

- (void)enableSingleTap {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSlideInTap)];
    [slideBannerView addGestureRecognizer:tapGesture];
}

-(void)setTapGestureForView {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissInApp)];
    [[self view] addGestureRecognizer:tapGesture];
}

-(void)setSwipeGestureForBannerView {
    UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissInAppWithSwipeDirection:)];
    [leftSwipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissInAppWithSwipeDirection:)];
    [rightSwipeGesture setDirection:UISwipeGestureRecognizerDirectionRight];
    
    [slideBannerView addGestureRecognizer:leftSwipeGesture];
    [slideBannerView addGestureRecognizer:rightSwipeGesture];
}

- (void)presentAnimationView {
    [self.view addSubview:slideBannerView];
    
    // Animate the slide in banner
    self.view.frame = CGRectMake(-1 * self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    [UIView animateWithDuration:1.0 animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

- (void)createNotificationView {
    CGRect frame = [self positionNotificationView];
    slideBannerView.frame = frame;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
        
    }
 }

- (void)showFromWindow:(BOOL)animated {
    if (!self.notification) return;
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationWillAppear:)]) {
        [[self inAppNotificationDelegate] inAppNotificationWillAppear:self.notification.notificationPayload];
    }
    
    [self createWindow];
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(inAppDidShow:fromViewController:)]) {
            [self.delegate inAppDidShow:self.notification.notificationPayload fromViewController:self];
        }
    };
    if (animated) {
        self.window.alpha = 1.0;
        completionBlock();
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}

- (void)hideFromWindow:(BOOL)animated withDirection:(UISwipeGestureRecognizerDirection) direction {
    void (^completionBlock)(void) = ^ {
        if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationWillDisappear:)]) {
            [[self inAppNotificationDelegate] inAppNotificationWillDisappear : self.notification.notificationPayload];
        }
        
        [self.window setHidden:YES];
        [self.window removeFromSuperview];
        self.window = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(inAppDidDismiss:fromViewController:)]) {
            [self.delegate inAppDidDismiss:self.notification.notificationPayload fromViewController:self];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:1.0 animations:^{
            double multiplier = kSlideToRightMultiplier;
            if (direction == UISwipeGestureRecognizerDirectionLeft) {
                multiplier = kSlideToLeftMultiplier;
            }
            self.view.frame = CGRectMake(multiplier * self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
            self.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}

- (void)initializeNotificationView {
    if (self.notification && self.notification.notificationContent) {
        CGFloat xPadding = 0.0;
        
        UILabel *iconLabel;
        if ([self isValidString: self.notification.notificationContent.icon]) {
            iconLabel = [self createIconLabel: xPadding];
            xPadding = iconLabel.frame.size.width;
        }
        
        UIView *iconView;
        if ([self isValidString: self.notification.notificationContent.iconImage]) {
            // get empty default width height view for calculating the padding
            iconView = [self createIconViewWithHeight:0];
            xPadding = xPadding + iconView.frame.size.width;
        }
        
        UILabel *actionButtonLabel;
        if ([self isValidString: self.notification.notificationContent.secondarIcon]) {
            actionButtonLabel = [self createActionButtonLabel];
        }
        
        UILabel *descriptionLabel;
        BlueShiftInAppLayoutMargin *messagePadding = [self fetchNotificationMessagePadding];
        if ([self isValidString: self.notification.notificationContent.message]) {
            BlueShiftInAppLayoutMargin *actionButtonPadding = [self fetchNotificationActionButtonPadding];
            CGFloat actionButtonRightPadding = (actionButtonPadding && actionButtonPadding.right > 0) ? actionButtonPadding.right : 0.0;
            CGFloat actionButtonLeftPadding = (actionButtonPadding && actionButtonPadding.left > 0) ? actionButtonPadding.left : 0.0;
            CGFloat actionButtonPosition = actionButtonLabel.frame.size.width + actionButtonLeftPadding + actionButtonRightPadding;
            
            CGFloat messageLeftPadding = (messagePadding && messagePadding.left > 0) ? messagePadding.left :0.0;
            CGFloat messageRightPadding = (messagePadding && messagePadding.right > 0) ? messagePadding.right : 0.0;
    
            CGFloat descriptionLabelWidth = slideBannerView.frame.size.width - (xPadding + messageLeftPadding + messageRightPadding + actionButtonPosition);
            xPadding = xPadding + messageLeftPadding;
            descriptionLabel = [self createDescriptionLabel:xPadding andLabelWidth:descriptionLabelWidth];
        }
        
        [self setBackgroundColor: slideBannerView];
        [self setBackgroundImageFromURL: slideBannerView];
        [self setBackgroundRadius: slideBannerView];
        
        if (self.notification.templateStyle == nil || self.notification.templateStyle.height <= 0) {
            CGFloat messageTopPadding = (messagePadding && messagePadding.top > 0) ? messagePadding.top :0.0;
            CGFloat messageBottomPadding = (messagePadding && messagePadding.bottom > 0) ? messagePadding.bottom : 0.0;
            CGFloat descriptionLabelHeight = descriptionLabel.frame.size.height + (messageTopPadding + messageBottomPadding);
            
            // Set height to icon height/image height/default min height if label height is less than min height
            // to align text veritically center
            if (descriptionLabelHeight < kSlideInInAppNotificationMinimumHeight) {
                if (iconLabel.frame.size.height > 0) {
                    descriptionLabelHeight = iconLabel.frame.size.height;
                } else if (iconView.frame.size.height > 0) {
                    descriptionLabelHeight = iconView.frame.size.height;
                } else {
                    descriptionLabelHeight = kSlideInInAppNotificationMinimumHeight;
                }
                
                CGRect descriptionLabelFrame = descriptionLabel.frame;
                descriptionLabelFrame.size.height = descriptionLabelHeight - messageTopPadding - messageBottomPadding;
                descriptionLabel.frame = descriptionLabelFrame;
            }
            
            CGRect frame = slideBannerView.frame;
            frame.size.height = descriptionLabelHeight;
            slideBannerView.frame = frame;
            
            [self createNotificationView];
        }
        
        if ([self isValidString: self.notification.notificationContent.icon]) {
            iconLabel.frame = CGRectMake(0.0, 0.0, iconLabel.frame.size.width, slideBannerView.frame.size.height);
            [slideBannerView addSubview: iconLabel];
        } else if ([self isValidString: self.notification.notificationContent.iconImage]) {
            // Recreate the icon view after getting exact size of the banner
            iconView = [self createIconViewWithHeight:slideBannerView.frame.size.height];
            [slideBannerView addSubview: iconView];
        }

        CGFloat actionXposition = slideBannerView.frame.size.width - actionButtonLabel.frame.size.width;
        actionButtonLabel.frame = CGRectMake(actionXposition, [self getCenterYPosition: actionButtonLabel.frame.size.height], actionButtonLabel.frame.size.width, actionButtonLabel.frame.size.height);
        [slideBannerView addSubview: actionButtonLabel];
        [slideBannerView addSubview: descriptionLabel];
    }
}

- (UIView *)createIconViewWithHeight:(CGFloat)bannerHeight {
    BlueShiftInAppLayoutMargin *iconImagePadding = [self fetchNotificationIconImagePadding];
    CGFloat leftPadding = (iconImagePadding && iconImagePadding.left > 0) ? iconImagePadding.left : 0.0;
    CGFloat topPadding = (iconImagePadding && iconImagePadding.top > 0) ? iconImagePadding.top : 0.0;
    CGFloat rightPadding = (iconImagePadding && iconImagePadding.right > 0) ? iconImagePadding.right : 0.0;
    CGFloat bottomPadding= (iconImagePadding && iconImagePadding.bottom > 0) ? iconImagePadding.bottom : 0.0;
    
    CGFloat iconImageWidth = kInAppNotificationModalIconWidth - (leftPadding + rightPadding);
    CGFloat iconImageHeight = kInAppNotificationModalIconHeight - (topPadding + bottomPadding);
    
    CGFloat iconViewHeight = bannerHeight == 0 ? kInAppNotificationModalIconHeight : bannerHeight;
    // Create a container view for the image
    UIView* iconView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, kInAppNotificationModalIconWidth, iconViewHeight)];
    // Return the iconView if bannerHeight is 0.
    if (bannerHeight == 0) {
        return iconView;
    }
    
    // Create imageView and set the image, padding and corner radius
    UIImageView *imageView = [[UIImageView alloc] initWithFrame: CGRectMake(leftPadding, topPadding, iconImageWidth, iconImageHeight)];
    // Set iconview center to show the image in the center when iconView height is more than the imageview height
    imageView.center = iconView.center;
    if (self.notification.notificationContent.iconImage) {
       [self loadImageFromURL:self.notification.notificationContent.iconImage forImageView:imageView];
    }
    CGFloat backgroundRadius = (self.notification.contentStyle && self.notification.contentStyle.iconImageBackgroundRadius && self.notification.contentStyle.iconImageBackgroundRadius.floatValue > 0) ? self.notification.contentStyle.iconImageBackgroundRadius.floatValue : 0.0;
    imageView.layer.cornerRadius = backgroundRadius;
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    // Set background color to the iconView
    if (self.notification.contentStyle && self.notification.contentStyle.iconImageBackgroundColor != (id)[NSNull null] && self.notification.contentStyle.iconImageBackgroundColor.length > 0) {
        NSString *backgroundColorCode = self.notification.contentStyle.iconImageBackgroundColor;
        iconView.backgroundColor = [self colorWithHexString:backgroundColorCode];
    }
    
    [iconView addSubview:imageView];
    iconView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    return iconView;
}

- (UILabel *)createIconLabel:(CGFloat)xPosition {
    BlueShiftInAppLayoutMargin *iconPadding = [self fetchNotificationIconPadding];
    CGFloat topPadding = (iconPadding && iconPadding.top > 0) ? iconPadding.top : 0.0;
    CGFloat bottomPadding = (iconPadding && iconPadding.bottom > 0) ? iconPadding.bottom : 0.0;
    CGFloat leftPadding = (iconPadding && iconPadding.left > 0) ? iconPadding.left : 0.0;
    CGFloat rightPadding = (iconPadding && iconPadding.right> 0) ? iconPadding.right : 0.0;
    
    CGFloat itemWidth = kInAppNotificationModalIconWidth + leftPadding + rightPadding;
    CGFloat itemHeight = kInAppNotificationModalIconHeight + topPadding +bottomPadding;
    CGRect cgRect = CGRectMake(0.0, 0.0, itemWidth, itemHeight);
    
    UILabel *label = [[UILabel alloc] initWithFrame:cgRect];
    
    CGFloat iconFontSize = (self.notification.contentStyle && self.notification.contentStyle.iconSize && self.notification.contentStyle.iconSize.floatValue > 0) ? self.notification.contentStyle.iconSize.floatValue : 22.0;
    
    [self applyIconToLabelView:label andFontIconSize:[NSNumber numberWithFloat:iconFontSize]];
    
    if (self.notification.contentStyle) {
        [self setLabelText: label andString: self.notification.notificationContent.icon labelColor:self.notification.contentStyle.iconColor backgroundColor:self.notification.contentStyle.iconBackgroundColor];
    }
    
    CGFloat iconRadius = (self.notification.contentStyle && self.notification.contentStyle.iconBackgroundRadius && self.notification.contentStyle.iconBackgroundRadius.floatValue > 0) ? self.notification.contentStyle.iconBackgroundRadius.floatValue : 0.0;
       
    label.layer.cornerRadius = iconRadius;
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [label setTextAlignment: NSTextAlignmentCenter];
    
    return label;
}

- (UILabel *)createDescriptionLabel:(CGFloat)xPosition andLabelWidth:(CGFloat)labelWidth{
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [descriptionLabel setNumberOfLines: 0];
    
    CGFloat fontSize =(self.notification.contentStyle && self.notification.contentStyle.messageSize && self.notification.contentStyle.messageSize.floatValue > 0) ? self.notification.contentStyle.messageSize.floatValue : 14.0;
    
    if (self.notification.contentStyle) {
        [self setLabelText: descriptionLabel andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
    }
    
    [descriptionLabel setFont:[UIFont fontWithName:@"Helvetica" size: fontSize]];
    CGFloat descriptionLabelHeight = [self getLabelHeight: descriptionLabel labelWidth: labelWidth];
    
    BlueShiftInAppLayoutMargin *descriptionPadding = [self fetchNotificationMessagePadding];
    CGFloat yPosition = (descriptionPadding && descriptionPadding.top > 0) ? descriptionPadding.top :0.0;
    CGRect cgRect = CGRectMake(xPosition, yPosition, labelWidth, descriptionLabelHeight);
    
    descriptionLabel.frame = cgRect;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    int textAlignment = (self.notification.contentStyle && self.notification.contentStyle.messageGravity) ? [self getTextAlignement: self.notification.contentStyle.messageGravity] : NSTextAlignmentCenter;
    [descriptionLabel setTextAlignment: textAlignment];
    
    return descriptionLabel;
}

- (UILabel *)createActionButtonLabel {
    BlueShiftInAppLayoutMargin *actionButtonPadding = [self fetchNotificationActionButtonPadding];
    CGFloat leftPadding = (actionButtonPadding && actionButtonPadding.left > 0) ? actionButtonPadding.left : 0.0;
    CGFloat rightPadding = (actionButtonPadding && actionButtonPadding.right > 0) ? actionButtonPadding.right : 0.0;
    CGFloat topPadding = (actionButtonPadding && actionButtonPadding.top > 0) ? actionButtonPadding.top : 0.0;
    CGFloat bottomPadding = (actionButtonPadding && actionButtonPadding.bottom > 0) ? actionButtonPadding.bottom : 0.0;
    
    CGFloat itemWidth = kInAppNotificationSlideBannerActionButtonWidth + leftPadding + rightPadding;
    CGFloat itemHeight = kInAppNotificationSlideBannerActionButtonHeight + topPadding + bottomPadding;
    CGRect cgrect = CGRectMake(0.0, 0.0, itemWidth, itemHeight);
    
    UILabel *actionButtonlabel = [[UILabel alloc] initWithFrame:cgrect];
    
    CGFloat iconFontSize = (self.notification.contentStyle && self.notification.contentStyle.secondaryIconSize && self.notification.contentStyle.secondaryIconSize.floatValue > 0) ? self.notification.contentStyle.secondaryIconSize.floatValue : 22;
    
    [self applyIconToLabelView: actionButtonlabel andFontIconSize:[NSNumber numberWithFloat:iconFontSize]];
    
    [self setLabelText: actionButtonlabel andString: self.notification.notificationContent.secondarIcon labelColor:self.notification.contentStyle.secondaryIconColor backgroundColor:self.notification.contentStyle.secondaryIconBackgroundColor];
    
    CGFloat iconRadius = 0.0;
    if (self.notification.contentStyle && self.notification.contentStyle.secondaryIconBackgroundRadius) {
        iconRadius = self.notification.contentStyle.secondaryIconBackgroundRadius.floatValue;
    }
       
    actionButtonlabel.layer.cornerRadius = iconRadius;
    actionButtonlabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [actionButtonlabel setTextAlignment: NSTextAlignmentCenter];
    
    return actionButtonlabel;
}

- (void)createBottomSafeAreaViewForFrame:(CGRect)slideInFrame {
    if(slideInFrame.size.height > 0 && [self getBottomSafeAreaHeight] > 0 && self.notification.templateStyle) {
        //Show safe area view only if bottom margin is zero and color is not empty/nil.
        if (self.notification.templateStyle.margin.bottom == 0 && self.notification.templateStyle.bottomSafeAreaColor && ![self.notification.templateStyle.bottomSafeAreaColor isEqualToString: @""]) {
            [bottomSafeAreaView removeFromSuperview];
            CGRect frame = slideInFrame;
            frame.size.height = [self getBottomSafeAreaHeight];
            frame.origin.y = slideInFrame.origin.y + slideInFrame.size.height;
            if (bottomSafeAreaView) {
                bottomSafeAreaView.frame = frame;
            } else {
                bottomSafeAreaView = [[UIView alloc] initWithFrame: frame];
                [bottomSafeAreaView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSlideInTap)]];
            }
            UIColor *backgroundColor = [self colorWithHexString: self.notification.templateStyle.bottomSafeAreaColor];
            [bottomSafeAreaView setBackgroundColor: backgroundColor];
            [self.view addSubview: bottomSafeAreaView];
        }
    }
}

- (CGFloat)getCenterYPosition:(CGFloat)height {
    CGFloat yPadding = height / 2.0;
    
    return ((slideBannerView.frame.size.height / 2) - yPadding);
}

#pragma mark - Public
-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated withDirection:UISwipeGestureRecognizerDirectionRight];
}

-(void)hideAnimated {
    [self hideFromWindow:YES withDirection:UISwipeGestureRecognizerDirectionRight];
}

- (void)handleSlideInTap {
    if (self.notification && self.notification.notificationContent && self.notification.notificationContent.actions &&
        self.notification.notificationContent.actions.count > 0 &&
        self.notification.notificationContent.actions[0]) {
        [self handleInAppButtonAction: self.notification.notificationContent.actions[0]];
    } else {
        [self hideAnimated];
    }
}

/// Dismiss in-app notification when user swipes the slide-in banner
-(void)dismissInAppWithSwipeDirection:(UISwipeGestureRecognizer *)recognizer {
    [self sendActionEventAnalytics:@{kNotificationClickElementKey:kInAppNotificationSwipeAction} forActionType:BlueshiftInAppDismissAction];
    switch (recognizer.direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            [self hideFromWindow:YES withDirection:UISwipeGestureRecognizerDirectionLeft];
            break;
        
        default:
            [self hideFromWindow:YES withDirection:UISwipeGestureRecognizerDirectionRight];
            break;
    }
}

/// Dismiss in-app notification when tapped outside the slide in notification
-(void)dismissInApp {
    [self sendActionEventAnalytics:@{kNotificationClickElementKey:kInAppNotificationTapOutsideAction} forActionType:BlueshiftInAppDismissAction];
    [self hideAnimated];
}

- (CGRect)positionNotificationView {
    float width = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ? self.notification.templateStyle.width : self.notification.width;
    float height = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? self.notification.templateStyle.height : [BlueShiftInAppNotificationHelper convertPointsHeightToPercentage :slideBannerView.frame.size.height forWindow:self.window];
    
    float topMargin = [self getTopSafeAreaHeight];
    float bottomMargin = [self getBottomSafeAreaHeight];
    float leftMargin = 0.0;
    float rightMargin = 0.0;
    if (self.notification.templateStyle && self.notification.templateStyle.margin) {
        if (self.notification.templateStyle.margin.top > 0) {
            topMargin = topMargin + self.notification.templateStyle.margin.top;
        }
        if (self.notification.templateStyle.margin.bottom > 0) {
            bottomMargin = bottomMargin + self.notification.templateStyle.margin.bottom;
        }
        if (self.notification.templateStyle.margin.left > 0) {
            leftMargin = self.notification.templateStyle.margin.left;
        }
        if (self.notification.templateStyle.margin.right > 0) {
            rightMargin = self.notification.templateStyle.margin.right;
        }
    }
    
    CGSize size = CGSizeZero;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPointsKey]) {
        size.width = width;
        size.height = height;
    } else if([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        CGFloat itemHeight = [BlueShiftInAppNotificationHelper convertPercentageHeightToPoints:height forWindow:self.window];
        CGFloat itemWidth =  (CGFloat) round([BlueShiftInAppNotificationHelper getApplicationWindowSize:self.window].width * (width / 100.0f));
        
        if (width == 100) {
            itemWidth = itemWidth - (leftMargin + rightMargin);
        }
        
        size.width = itemWidth;
        size.height = itemHeight;
    }
    
    CGRect frame = slideBannerView.frame;
    frame.size = size;
    slideBannerView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [BlueShiftInAppNotificationHelper getApplicationWindowSize:self.window];
    NSString* position = (self.notification.templateStyle && self.notification.templateStyle.position) ? self.notification.templateStyle.position : self.notification.position;
    
    frame.origin.x = leftMargin;
    if([position  isEqual: kInAppNotificationModalPositionTopKey]) {
        frame.origin.y = 0.0f + topMargin;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else if([position  isEqual: kInAppNotificationModalPositionCenterKey]) {
        frame.origin.y = (screenSize.height - size.height) / 2.0f;
    } else if([position  isEqual: kInAppNotificationModalPositionBottomKey]) {
        frame.origin.y = screenSize.height - (size.height + bottomMargin);
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
        [self createBottomSafeAreaViewForFrame:frame];
    } else {
        frame.origin.y = (screenSize.height - size.height) / 2.0f;
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    slideBannerView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
}

/// get bottom safe area height for the current in-app window
- (CGFloat)getBottomSafeAreaHeight {
    CGFloat extraBottomPadding = 0.0;
    if (@available(iOS 11.0, *)) {
        extraBottomPadding = [BlueShiftInAppNotificationHelper getApplicationWindowSafeAreaInsets: self.window].bottom;
    }
    return extraBottomPadding;
}

/// get top safe area height for the current in-app window
- (CGFloat)getTopSafeAreaHeight {
    CGFloat topSafeAreaHeight = 0.0;
    if (@available(iOS 11.0, *)) {
        topSafeAreaHeight = [BlueShiftInAppNotificationHelper getApplicationWindowSafeAreaInsets: self.window].top;
    } else {
        topSafeAreaHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    return topSafeAreaHeight;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationIconImagePadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.iconImagePadding)
    ? self.notification.contentStyle.iconImagePadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationIconPadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.iconPadding)
       ? self.notification.contentStyle.iconPadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationMessagePadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.messagePadding)
       ? self.notification.contentStyle.messagePadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationActionButtonPadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.actionsPadding) ? self.notification.contentStyle.actionsPadding : NULL;
}

@end
