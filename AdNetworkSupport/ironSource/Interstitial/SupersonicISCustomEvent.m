//
//  SupersonicInterstitialCustomEvent.m
//  MoPubSampleApp
//
//  Created by Avi Levinshtein on 29/06/2016.
//  Copyright © 2016 MoPub. All rights reserved.
//

#import "SupersonicISCustomEvent.h"
#import "MPLogging.h"

@interface SupersonicISCustomEvent()

@end

@implementation SupersonicISCustomEvent

static int initState;
static int INIT_NOT_STARTED = 0;
static int INIT_PENDING = 1;
static int INIT_SUCCEEDED = 2;
static bool isISTestEnabled;

#pragma mark init dealloc Methods
- (instancetype)init {
    self = [super init];
    if (self) {
        if(!initState) {
            initState = INIT_NOT_STARTED;
        }
         MPLogInfo(@"general init");
    }
    return self;
}

- (void)dealloc {
    MPLogInfo(@"general dealloc");
}

- (void) initISSupersonicSDKWithAppKey: (NSString*) appKey {
    if (initState == INIT_NOT_STARTED) {
        [self onLog:@"initISSupersonicSDKWithAppKey"];
        initState = INIT_PENDING;
        [SupersonicConfiguration getConfiguration].plugin = @"MoPub";
        [SupersonicConfiguration getConfiguration].pluginVersion = @"1.0.1";
        [SupersonicConfiguration getConfiguration].pluginFrameworkVersion = MP_SDK_VERSION;
        
        MPLogInfo(@"initSupersonicSDK was requested");
        UIDevice *device = [UIDevice currentDevice];
        NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
        
        [[Supersonic sharedInstance] initISWithAppKey:appKey withUserId:currentDeviceId];
    }
}

- (void) loadISSupersonicSDK {
    [self onLog:@"loadISSupersonicSDK"];
    if([[Supersonic sharedInstance] isInterstitialAvailable]) {
        [self.delegate interstitialCustomEvent:self didLoadAd:self];
    } else {
        [[Supersonic sharedInstance] loadIS];
    }
}

- (void) onLog: (NSString *) log {
    if(isISTestEnabled) {
        NSLog(@"SupersonicISCustomEvent: %@" , log);
    }
}


#pragma mark Mopub methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info {
    [self onLog:@"requestInterstitialWithCustomEventInfo"];
    NSString* applicationKey = @"";
    
    if([info objectForKey:@"isTestEnabled"] != nil){
        isISTestEnabled = [[info objectForKey:@"isTestEnabled"] boolValue];
    }
    
    if([info objectForKey:@"applicationKey"] != nil){
        applicationKey = [info objectForKey:@"applicationKey"];
    }
    
    MPLogInfo(@"Supersonic Interstital is requested");
    [[Supersonic sharedInstance] setISDelegate:self];
    if(applicationKey && applicationKey.length > 0) {
        [self initISSupersonicSDKWithAppKey:applicationKey];
        
        if(initState == INIT_SUCCEEDED) {
            [self loadISSupersonicSDK];
        }
    }
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [self onLog:@"showInterstitialFromRootViewController"];
    if([[Supersonic sharedInstance] isInterstitialAvailable]) {
        [[Supersonic sharedInstance] showISWithViewController:rootViewController];
    } else {
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

#pragma mark Supersonic Delegates implementation

/*!
 * @discussion Called when initiation process of the Interstitial ad unit has finished successfully.
 */
- (void)supersonicISInitSuccess {
    [self onLog:@"supersonicISInitSuccess"];
    initState = INIT_SUCCEEDED;
    [self loadISSupersonicSDK];
}

/*!
 * @discussion Called when initiation stage fails, or if you have a problem in the integration.
 *
 *              You can learn about the reason by examining the 'error' value
 */
- (void)supersonicISInitFailedWithError:(NSError *)error {
    [self onLog:@"supersonicISInitFailedWithError"];
    initState = INIT_NOT_STARTED;
}

/*!
 * @discussion Called each time an ad is available
 */
- (void)supersonicISReady {
    [self onLog:@"supersonicISReady"];
    [self.delegate interstitialCustomEvent:self didLoadAd:self];
}

/*!
 * @discussion Called each time an ad is not available
 */
- (void)supersonicISFailed {
    [self onLog:@"supersonicISFailed"];
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

/*!
 * @discussion Called each time the Interstitial window is about to open
 */
- (void)supersonicISAdOpened {
    [self onLog:@"supersonicISAdOpened"];
    [self.delegate interstitialCustomEventWillAppear:self];
}

/*!
 * @discussion Called each time the Interstitial window is about to close
 */
- (void)supersonicISAdClosed {
    [self onLog:@"supersonicISAdClosed"];
    [self.delegate interstitialCustomEventWillDisappear:self];
    [self.delegate interstitialCustomEventDidDisappear:self];
}

/*!
 * @discussion Called each time the Interstitial window has opened successfully.
 */
- (void)supersonicISShowSuccess {
    [self onLog:@"supersonicISShowSuccess"];
    [self.delegate interstitialCustomEventDidAppear:self];
}

/*!
 * @discussion Called if showing the Interstitial for the user has failed.
 *
 *              You can learn about the reason by examining the ‘error’ value
 */
- (void)supersonicISShowFailWithError:(NSError *)error {
    [self onLog:@"supersonicISShowFailWithError"];
    [self.delegate interstitialCustomEventDidExpire:self];
}

/*!
 * @discussion Called each time the end user has clicked on the Interstitial ad.
 */
- (void)supersonicISAdClicked {
    [self onLog:@"supersonicISAdClicked"];
    [self.delegate interstitialCustomEventDidReceiveTapEvent:self];
}

@end
