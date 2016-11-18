//
//  MPAdServerCommunicator.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPAdServerCommunicator.h"

#import "MPAdConfiguration.h"
#import "MPLogging.h"
#import "MPCoreInstanceProvider.h"
#import "MPLogEvent.h"
#import "MPLogEventRecorder.h"

const NSTimeInterval kRequestTimeoutInterval = 10.0;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPAdServerCommunicator ()

@property (nonatomic, assign, readwrite) BOOL loading;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) MPLogEvent *adRequestLatencyEvent;

- (NSError *)errorForStatusCode:(NSInteger)statusCode;
- (NSURLRequest *)adRequestForURL:(NSURL *)URL;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdServerCommunicator

@synthesize delegate = _delegate;
@synthesize URL = _URL;
@synthesize task = _task;
@synthesize loading = _loading;

- (id)initWithDelegate:(id<MPAdServerCommunicatorDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [self.task cancel];
}

#pragma mark - Public

- (void)loadURL:(NSURL *)URL
{
    [self cancel];
    self.URL = URL;

    // Start tracking how long it takes to successfully or unsuccessfully retrieve an ad.
    self.adRequestLatencyEvent = [[MPLogEvent alloc] initWithEventCategory:MPLogEventCategoryRequests eventName:MPLogEventNameAdRequest];
    self.adRequestLatencyEvent.requestURI = URL.absoluteString;
    
    __weak typeof(self) weakSelf = self;
    self.task = [[NSURLSession sharedSession] dataTaskWithRequest:[self adRequestForURL:URL]
                                                completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        if (![weakSelf continueWithResponse:response])
            return;
        
        if (error != nil || data == nil)
        {
            // Do not record a logging event if we failed to make a connection.
            weakSelf.adRequestLatencyEvent = nil;
            
            weakSelf.loading = NO;
            [weakSelf.delegate communicatorDidFailWithError:error];
            return;
        }
        
        [weakSelf connectionDidFinishLoadingWithData:data andHeaders:[(NSHTTPURLResponse *)response allHeaderFields]];
    }];
    [self.task resume];
    
    self.loading = YES;
}

- (void)cancel
{
    self.adRequestLatencyEvent = nil;
    self.loading = NO;
    [self.task cancel];
    self.task = nil;
}

#pragma mark - NSURLSession handling

- (BOOL)continueWithResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode >= 400) {
            // Do not record a logging event if we failed to make a connection.
            self.adRequestLatencyEvent = nil;
            
            [self.task cancel];
            self.loading = NO;
            [self.delegate communicatorDidFailWithError:[self errorForStatusCode:statusCode]];
            return NO;
        }
    }
    return YES;
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data andHeaders:(NSDictionary *)headerFields
{
    [self.adRequestLatencyEvent recordEndTime];
    self.adRequestLatencyEvent.requestStatusCode = 200;

    MPAdConfiguration *configuration = [[MPAdConfiguration alloc] initWithHeaders:headerFields
                                                                             data:data];
    
    MPAdConfigurationLogEventProperties *logEventProperties =
        [[MPAdConfigurationLogEventProperties alloc] initWithConfiguration:configuration];

    // Do not record ads that are warming up.
    if (configuration.adUnitWarmingUp) {
        self.adRequestLatencyEvent = nil;
    } else {
        [self.adRequestLatencyEvent setLogEventProperties:logEventProperties];
        MPAddLogEvent(self.adRequestLatencyEvent);
    }

    self.loading = NO;
    [self.delegate communicatorDidReceiveAdConfiguration:configuration];
}

#pragma mark - Internal

- (NSError *)errorForStatusCode:(NSInteger)statusCode
{
    NSString *errorMessage = [NSString stringWithFormat:
                              NSLocalizedString(@"MoPub returned status code %d.",
                                                @"Status code error"),
                              statusCode];
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:errorMessage
                                                          forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"mopub.com" code:statusCode userInfo:errorInfo];
}

- (NSURLRequest *)adRequestForURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [[MPCoreInstanceProvider sharedProvider] buildConfiguredURLRequestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:kRequestTimeoutInterval];
    return request;
}

@end
