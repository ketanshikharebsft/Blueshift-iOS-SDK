//
//  BlueShiftNotificationWebViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import <WebKit/WebKit.h>
#import "BlueShiftNotificationWebViewController.h"
#import "BlueShiftNotificationView.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotificationDelegate.h"
#import "BlueshiftLog.h"

API_AVAILABLE(ios(8.0))
@interface BlueShiftNotificationWebViewController ()<WKNavigationDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    WKWebView *webView;
    BOOL isAutoHeight;
    BOOL isAutoWidth;
}

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;
@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;

@end

@implementation BlueShiftNotificationWebViewController

- (void)loadView {
    if (self.canTouchesPassThroughWindow) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setupWebView {
    [self setAutomaticScale];
    [self configureBackground];
    [self presentWebViewNotification];
    [self initialiseWebView];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UIButton class]]) {
            [view removeFromSuperview];
        }
    }
    [self initialiseWebView];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    //Resize webview on orientation change
    [self resizeWebViewAsPerContent:webView];
}

- (void)setAutomaticScale {
    isAutoWidth = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ?  NO: YES;
    isAutoHeight = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? NO : YES;
}

- (void)configureBackground {
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)presentWebViewNotification{
    if (@available(iOS 8.0, *)) {
        WKWebView *webView = [self createWebView];
        [self setWebViewDelegate:webView];
        [self addWebViewAsSubView:webView];
        [self loadWebView];
    }
}

- (void)loadWebView {
    if (self.notification.notificationContent.url) {
        [self loadFromURL];
    } else{
        [self loadFromHTML];
    }
}

-(void)initialiseWebView {
    CGRect frame = [self positionWebView];
    [self configureWebViewBackground];
    [self createCloseButton:frame];
    [self setBackgroundDim];
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
      webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
      webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}

- (WKWebView *)createWebView  API_AVAILABLE(ios(8.0)){
    WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
    wkConfig.allowsInlineMediaPlayback = YES;
    webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:wkConfig];
    webView.scrollView.showsHorizontalScrollIndicator = NO;
    webView.scrollView.showsVerticalScrollIndicator = NO;
    webView.scrollView.scrollEnabled = YES;
    webView.scrollView.bounces = NO;
    webView.backgroundColor = [UIColor whiteColor];
    webView.opaque = NO;
    webView.tag = 188293;
    webView.clipsToBounds = TRUE;
    [self setBackgroundRadius:webView];
    return webView;
}

- (void)setWebViewDelegate:(WKWebView *)webView  API_AVAILABLE(ios(8.0)){
    webView.navigationDelegate = self;
    webView.scrollView.delegate = self;
}

- (void)addWebViewAsSubView:(WKWebView *)webView  API_AVAILABLE(ios(8.0)){
    [self.view addSubview:webView];
}

- (void)loadFromURL {
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.notification.notificationContent.url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0]];
    webView.navigationDelegate = nil;
}

- (void)loadFromHTML {
    [webView loadHTMLString:[kInAppNotificationModalHTMLHeaderKey stringByAppendingString: self.notification.notificationContent.content] baseURL:nil];
}

- (CGRect)positionWebView{
    float width = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ?  self.notification.templateStyle.width: 0;
    float height = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? self.notification.templateStyle.height : 0;
    
    if (isAutoWidth && width == 0) {
        //If ipad, set the width to max width
        if ([BlueShiftInAppNotificationHelper isIpadDevice]) {
            width = [BlueShiftInAppNotificationHelper convertPointsWidthToPercentage:kInAppNotificationMaximumWidthInPoints forWindow:self.window];
        } else {
            float deviceWidth = [BlueShiftInAppNotificationHelper convertPercentageWidthToPoints:kInAppNotificationDefaultWidth forWindow:self.window];
            //If iPhone orientation is landscape, set the width to max width
            if (deviceWidth > kInAppNotificationMaximumWidthInPoints) {
                width = [BlueShiftInAppNotificationHelper convertPointsWidthToPercentage:kInAppNotificationMaximumWidthInPoints forWindow:self.window];
            } else {
                //If iPhone orientation is portrait, set the width to default 95%
                width = kInAppNotificationDefaultWidth;
            }
        }
    } else {
        width = self.notification.templateStyle.width;
    }
    if (isAutoHeight && height == 0) {
        height = kHTMLInAppNotificationMinimumHeight;
    } else {
        height = self.notification.templateStyle.height;
    }
    
    float topMargin = 0.0;
    float bottomMargin = 0.0;
    float leftMargin = 0.0;
    float rightMargin = 0.0;
    if (self.notification.templateStyle && self.notification.templateStyle.margin) {
        if (self.notification.templateStyle.margin.top > 0) {
            topMargin = topMargin + self.notification.templateStyle.margin.top;
        }
        if (self.notification.templateStyle.margin.bottom > 0) {
            bottomMargin = self.notification.templateStyle.margin.bottom;
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
        CGFloat maxWidth = [BlueShiftInAppNotificationHelper getPresentationAreaWidthForWindow:self.window];
        if(maxWidth > width) {
            size.width = width;
        } else {
            size.width = maxWidth;
        }
        CGFloat maxHeight = [BlueShiftInAppNotificationHelper getPresentationAreaHeightForWindow:self.window];
        if(maxHeight > height) {
            size.height = height;
        } else {
            size.height = maxHeight;
        }
    } else if([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        CGFloat itemHeight = [BlueShiftInAppNotificationHelper convertPercentageHeightToPoints:height forWindow:self.window];
        CGFloat itemWidth = [BlueShiftInAppNotificationHelper convertPercentageWidthToPoints:width forWindow:self.window];
        
        if (width == 100) {
            itemWidth = itemWidth - (leftMargin + rightMargin);
        }
        
        if (height == 100) {
            itemHeight = itemHeight - (topMargin + bottomMargin);
        }
        
        size.width = itemWidth;
        size.height = itemHeight;
    }else {
        
    }
    
    // prevent webview content insets for Cover
    if (@available(iOS 11.0, *)) {
        if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey] && height == 100.0) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    
    CGRect frame = webView.frame;
    frame.size = size;
    webView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [BlueShiftInAppNotificationHelper getApplicationWindowSize:self.window];
    
    NSString* position = (self.notification.templateStyle && self.notification.templateStyle.position) ? self.notification.templateStyle.position : self.notification.position;
    
    int extra = (int) (self.notification.templateStyle && [self.notification.templateStyle.enableCloseButton boolValue] ? ( KInAppNotificationModalCloseButtonWidth/ 2.0f) : 0.0f);
    
    if([position  isEqual: kInAppNotificationModalPositionTopKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = 0.0f + extra + 20.0f;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else if([position  isEqual:  kInAppNotificationModalPositionCenterKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        double yPosition = (screenSize.height - size.height) / 2.0f;
        frame.origin.y = yPosition;
    } else if([position  isEqual: kInAppNotificationModalPositionBottomKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = screenSize.height - size.height;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
    } else {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        double yPosition = (screenSize.height - size.height) / 2.0f;
        frame.origin.y = yPosition;
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    webView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler API_AVAILABLE(ios(8.0)) {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        [self handleInAppWebViewActionForURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)handleInAppWebViewActionForURL:(NSURL*)url {
    @try {
        NSDictionary *details = [NSDictionary dictionary];
        if (url) {
            NSString *encodedURLString = [BlueShiftInAppNotificationHelper getEncodedURLString:url.absoluteString];
            details = @{kNotificationURLElementKey:encodedURLString};
            [self processInAppActionForDeepLink:url.absoluteString details:details];
        } else {
            [self processInAppActionForDeepLink:nil details:details];
        }
        NSDictionary *inAppOptions = [self getInAppOpenURLOptions:nil];
        if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(actionButtonDidTapped:)]) {
            NSString *deepLink = (url && url.absoluteString) ? url.absoluteString : @"";
            NSMutableDictionary *actionPayload = [[NSMutableDictionary alloc] initWithDictionary:inAppOptions];
            [actionPayload setObject: deepLink forKey: kInAppNotificationModalPageKey];
            [actionPayload setObject:kInAppNotificationButtonTypeOpenKey forKey: kInAppNotificationButtonTypeKey];
            [[self inAppNotificationDelegate] actionButtonDidTapped: actionPayload];
        } else if([url.absoluteString isEqualToString:kInAppNotificationDismissDeepLinkURL] ||
                  [url.absoluteString isEqualToString:kInAppNotificationReqPNPermissionDeepLinkURL]) {
            // Placeholder
            // Do not send the deep links with type dismiss or ask-pn-permission to openURL:options:
            // This case is already handled in the [self processInAppActionForDeepLink:]
        }
        else if(url && [BlueShift sharedInstance].appDelegate.mainAppDelegate &&
                  [[BlueShift sharedInstance].appDelegate.mainAppDelegate respondsToSelector:@selector(application:openURL:options:)] &&
                  [BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:url.absoluteString]) {
            if (@available(iOS 9.0, *)) {
                [[BlueShift sharedInstance].appDelegate.mainAppDelegate application:[UIApplication sharedApplication] openURL: url options:inAppOptions];
                [BlueshiftLog logInfo:[NSString stringWithFormat:@"%@ %@",@"Delivered in-app notification deeplink to AppDelegate openURL method, Deep link - ", [url absoluteString]] withDetails:inAppOptions methodName:nil];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    [self hideFromWindow:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable complete, NSError * _Nullable error) {
        if (complete) {
            [BlueshiftLog logInfo:@"Webview loaded the content successfully." withDetails:nil methodName:nil];
            [self showInAppOnWebViewLoad];
        } else if(error) {
            [BlueshiftLog logInfo:@"Failed to load Webview content." withDetails:nil methodName:nil];
            [self showInAppOnWebViewLoad];
        }
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [BlueshiftLog logInfo:@"Failed to finish webview navigation." withDetails:nil methodName:nil];
    [self showInAppOnWebViewLoad];
}

- (void)showInAppOnWebViewLoad {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([self delegate] && [[self delegate] respondsToSelector:@selector(presentInAppViewController:forNotification:)]) {
            [[self delegate] presentInAppViewController:self forNotification:self.notification];
        }
        [self resizeWebViewAsPerContent:self->webView];
    });
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [scrollView.pinchGestureRecognizer setEnabled:false];
}

//resize webview as per content height & width when all the content/media is loaded
- (void)resizeWebViewAsPerContent:(WKWebView *)webView  {
    [BlueshiftLog logInfo:@"Resizing the in-app webview size based on the loaded content." withDetails:nil methodName:nil];
    [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable height, NSError * _Nullable error) {
        [webView evaluateJavaScript:@"document.body.scrollWidth" completionHandler:^(id _Nullable width, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setHeightWidthAsPerHTMLContentWidth:[width floatValue] height:[height floatValue]];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            });
        }];
    }];
}

- (void)setHeightWidthAsPerHTMLContentWidth:(float) width height:(float)height {
    if(isAutoHeight || isAutoWidth) {
        self.notification.dimensionType = kInAppNotificationModalResolutionPointsKey;
        if (isAutoWidth) {
            CGFloat maxWidth = [BlueShiftInAppNotificationHelper convertPercentageWidthToPoints:kInAppNotificationDefaultWidth forWindow:self.window];
            //If content width is greater than the screen width, then set width to max width else set to content height
            if(maxWidth > width) {
                self.notification.templateStyle.width = width;
            } else {
                self.notification.templateStyle.width = maxWidth;
            }
        } else {
            self.notification.templateStyle.width = webView.frame.size.width;
        }
        if (isAutoHeight) {
            CGFloat maxHeight = [BlueShiftInAppNotificationHelper getPresentationAreaHeightForWindow:self.window];
            //If content height is greater than the screen width, then set width to max height else set to content height
            if(maxHeight > height) {
                self.notification.templateStyle.height = height;
            } else {
                self.notification.templateStyle.height = maxHeight;
            }
        } else {
            self.notification.templateStyle.height = webView.frame.size.height;
        }
    }
}

- (void)configureWebViewBackground {
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
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
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 1.0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}

-(void)hideFromWindow:(BOOL)animated {
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
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    if (!self.notification.notificationContent.content) return;
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}


@end
