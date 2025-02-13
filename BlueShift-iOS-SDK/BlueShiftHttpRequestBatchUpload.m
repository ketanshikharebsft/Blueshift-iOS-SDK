//
//  BlueShiftHttpRequestBatchUpload.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftHttpRequestBatchUpload.h"
#import "BlueshiftLog.h"

#define kBatchSize  100

@interface BlueShiftHttpRequestBatchUpload ()

+ (void)createBatchesWithContext: (NSManagedObjectContext*)masterContext withBatchList: (NSMutableArray*) batchList;

+ (void) deleteBatchRecords:(BatchEventEntity *)batchEvent context:(NSManagedObjectContext*) context completetionHandler:(void (^)(BOOL))handler;

+ (void) handleRetryBatchUpload:(BatchEventEntity *)batchEvent context:(NSManagedObjectContext*)context requestOperation: (BlueShiftBatchRequestOperation*)requestOperation completetionHandler:(void (^)(BOOL))handler;

@end

// Shows the status of the batch upload request queue
static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
static NSTimer *_batchUploadTimer = nil;

@implementation BlueShiftHttpRequestBatchUpload

+ (void)startBatchUpload {
    // Create timer only if tracking is enabled
    if ([BlueShift sharedInstance].isTrackingEnabled && _batchUploadTimer == nil) {
        [BlueshiftLog logInfo:@"Starting the batch upload timer." withDetails:nil methodName:nil];
        _batchUploadTimer = [NSTimer scheduledTimerWithTimeInterval:[[BlueShiftBatchUploadConfig sharedInstance] fetchBatchUploadTimer] target:self selector:@selector(batchEventsUploadInBackground) userInfo:nil repeats:YES];
    }
}

+ (void)stopBatchUpload {
    if (_batchUploadTimer) {
        [BlueshiftLog logInfo:@"Stopping the batch upload." withDetails:nil methodName:nil];
        [_batchUploadTimer invalidate];
        _batchUploadTimer = nil;
    }
}


// Perform batch upload task in background
+ (void)batchEventsUploadInBackground {
    [self performSelectorInBackground:@selector(createAndUploadBatches) withObject:nil];
}

// Create and upload batches
+ (void)createAndUploadBatches {
    [self createBatches];
    [self uploadBatches];
}

+ (void)createBatches {
    @synchronized(self) {
        [HttpRequestOperationEntity fetchBatchWiseRecordFromCoreDataWithCompletetionHandler:^(BOOL status, NSArray *results) {
            if(status) {
                NSMutableArray *batchList = [[NSMutableArray alloc] init];
                NSUInteger batchLength = results.count/kBatchSize;
                if (results.count % kBatchSize != 0) {
                    batchLength = batchLength + 1;
                }
                for (NSUInteger i = 0; i < batchLength; i++) {
                    NSArray *operationEntitiesToBeExecuted = [[NSArray alloc] init];
                    NSRange range;
                    range.location = i * kBatchSize;
                    if (i == batchLength-1) {
                        range.length = results.count % kBatchSize;
                    } else {
                        range.length = kBatchSize;
                    }
                    operationEntitiesToBeExecuted = [results subarrayWithRange:range];
                    [batchList addObject:operationEntitiesToBeExecuted];
                }
                BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
                NSManagedObjectContext *masterContext;
                if (appDelegate) {
                    @try {
                        masterContext = appDelegate.realEventManagedObjectContext;
                    }
                    @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }
                if(masterContext) {
                    [BlueShiftHttpRequestBatchUpload createBatchesWithContext:masterContext withBatchList:batchList];
                }
            }
        }];
    }
}

+ (void)createBatchesWithContext: (NSManagedObjectContext*)masterContext withBatchList: (NSMutableArray*) batchList  {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = masterContext;
    if(context) {
        for (NSArray *operationEntitiesToBeExecuted in batchList) {
            NSMutableArray *paramsArray = [[NSMutableArray alloc]init];
            for(HttpRequestOperationEntity *operationEntityToBeExecuted in operationEntitiesToBeExecuted) {
                if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]) {
                    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                    if(requestOperation.parameters != nil) {
                        [paramsArray addObject:requestOperation.parameters];
                    }
                    @try {
                        if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                            [masterContext performBlockAndWait:^{
                                [masterContext deleteObject:operationEntityToBeExecuted];
                            }];
                        }
                    }
                    @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }
            }
            [self createBatch:paramsArray];
            if (context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlockAndWait:^{
                    @try {
                        NSError *saveError = nil;
                        if ([context hasChanges]) {
                            [context save:&saveError];
                        }
                        [masterContext performBlockAndWait:^{
                            @try {
                                NSError *saveError = nil;
                                if (masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                                    [masterContext save:&saveError];
                                }
                            }
                            @catch (NSException *exception) {
                                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                            }
                        }];
                    }
                    @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }];
            }
        }
    }
}

+ (void)createBatch:(NSArray *)paramsArray {
    BlueShiftBatchRequestOperation *requestOperation = [[BlueShiftBatchRequestOperation alloc] initParametersList:paramsArray andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0];
    [BlueShiftRequestQueue addBatchRequestOperation:requestOperation];
}

// Upload all batches one by one
+ (void)uploadBatches {
    if (BlueShift.sharedInstance.config.apiKey) {
        [BatchEventEntity fetchBatchesFromCoreDataWithCompletetionHandler:^(BOOL status, NSArray *batches) {
            if (status) {
                if(batches && batches.count > 0) {
                    [self uploadBatchAtIndex:0 fromBatches:batches];
                }
            }
        }];
    }
}

+ (void)uploadBatchAtIndex:(int)index fromBatches:(NSArray *)batches {
    if(index == batches.count) {
        return;
    } else {
        BatchEventEntity *batchEvent = [batches objectAtIndex:index];
        [self processRequestsInQueue:batchEvent completetionHandler:^(BOOL status) {
            [self uploadBatchAtIndex:index+1 fromBatches:batches];
        }];
    }
}


+ (void) processRequestsInQueue:(BatchEventEntity *)batchEvent completetionHandler:(void (^)(BOOL))handler {
    @synchronized(self) {
        // Process requet when requestQueue and internet is available
        if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES) {
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
            if(appDelegate) {
                NSManagedObjectContext *context;
                @try {
                    context = appDelegate.batchEventManagedObjectContext;
                }
                @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
                if(context != nil) {
                    BlueShiftBatchRequestOperation *requestOperation = [[BlueShiftBatchRequestOperation alloc]initWithBatchRequestOperationEntity:batchEvent];
                    
                    if (requestOperation != nil) {
                        // Set request queue to busy to process it
                        _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
                        
                        // Performs the request operation
                        [BlueShiftHttpRequestBatchUpload performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
                            if (status == YES) {
                                // delete batch records for the request operation if it is successfully executed
                                [BlueShiftHttpRequestBatchUpload deleteBatchRecords:batchEvent context:context completetionHandler:handler];
                            } else {
                                // Retry the request when fails
                                [BlueShiftHttpRequestBatchUpload handleRetryBatchUpload:batchEvent context:context requestOperation:requestOperation completetionHandler:handler];
                            }
                        }];
                    }
                }
            }
        }
    }
}

+ (void) deleteBatchRecords:(BatchEventEntity *)batchEvent context:(NSManagedObjectContext*) context completetionHandler:(void (^)(BOOL))handler {
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                @try {
                    [context deleteObject:batchEvent];
                    NSError *saveError = nil;
                    if(context) {
                        [context save:&saveError];
                    }
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    handler(YES);
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    handler(NO);
                }
            }];
        }
        else {
            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
            handler(NO);
        }
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
        handler(NO);
    }
}

+ (void) handleRetryBatchUpload:(BatchEventEntity *)batchEvent context:(NSManagedObjectContext*)context requestOperation: (BlueShiftBatchRequestOperation*)requestOperation completetionHandler:(void (^)(BOOL))handler {
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                @try {
                    // Delete the existing record
                    [context deleteObject:batchEvent];
                    NSError *saveError = nil;
                    if(context) {
                        [context save:&saveError];
                        NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                        requestOperation.retryAttemptsCount = retryAttemptsCount - 1;
                        requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
                        // Add a new entry if eligible, with modified retry attempt and timestamp
                        if (requestOperation.retryAttemptsCount > 0) {
                            [BlueShiftRequestQueue addBatchRequestOperation:requestOperation];
                            [self retryBatchUpload];
                        }
                    }
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    handler(YES);
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    handler(NO);
                }
            }];
        } else {
            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
            handler(NO);
        }
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
        handler(NO);
    }
}


// Schedule the retry batch upload
+ (void)retryBatchUpload {
    [NSTimer scheduledTimerWithTimeInterval:kRequestRetryMinutesInterval * 60
                                     target:self
                                   selector:@selector(retryBatchEventsUploadInBackground)
                                   userInfo:nil
                                    repeats:NO];
}

// Perform retry batch upload task in background
+ (void)retryBatchEventsUploadInBackground {
    if ([BlueShift sharedInstance].isTrackingEnabled) {
        [self performSelectorInBackground:@selector(uploadBatches) withObject:nil];
    }
}

+ (void)performRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation completetionHandler:(void (^)(BOOL))handler {
    NSString *url = [BlueshiftRoutes getBulkEventsURL];
    
    NSMutableArray *parametersArray = (NSMutableArray*)requestOperation.paramsArray;
    if ((!parametersArray) || (parametersArray.count == 0)){
        handler(YES);
        return;
    }
    NSDictionary *paramsDictionary = @{@"events": parametersArray};
    [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:paramsDictionary completetionHandler:^(BOOL status, NSDictionary* response, NSError *error) {
        handler(status);
    }];
}

@end
