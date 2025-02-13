//
//  BlueshiftRoutes.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#ifndef BlueShift_iOS_SDK_BlueShiftRoutes_h
#define BlueShift_iOS_SDK_BlueShiftRoutes_h


#define kBS_USBaseURL              @"https://api.getblueshift.com/"
#define kBS_EUBaseURL              @"https://api.eu.getblueshift.com/"
#define kBSRealtimeEvent           @"api/v1/event"
#define kBSBulkEvents              @"api/v1/bulkevents"
#define kBSTrackAPI                @"track"
#define kBSLiveContent             @"live"
#define kBSInAppMessages           @"inapp/msg"

@interface BlueshiftRoutes : NSObject

+ (NSString*)getBaseURLString;
+ (NSString*)getRealtimeEventsURL;
+ (NSString*)getBulkEventsURL;
+ (NSString*)getTrackURL;
+ (NSString*)getLiveContentURL;
+ (NSString*)getInAppMessagesURL;

@end


#endif
