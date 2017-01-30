//
//  SupersonicRVCustomEvent.m
//  MoPubSampleApp
//
//  Created by Avi Levinshtein on 24/08/2016.
//  Copyright © 2016 MoPub. All rights reserved.
//

#import "SupersonicRVCustomEvent.h"
#import "MPLogging.h"

@interface SupersonicRVCustomEvent()

#pragma mark Mopub server properties
@property (nonatomic, assign) NSString* placementName;
@property (nonatomic, assign) NSString* moPubId;

#pragma mark Class local properties
@property (nonatomic, strong) MPRewardedVideoReward *reward;

@end

@implementation SupersonicRVCustomEvent

static BOOL isRVInitSuccess;
static NSMutableDictionary * moPubLoadedInventory;
static bool isRVTestEnabled;

#pragma mark init dealloc Methods
- (instancetype)init {
    self = [super init];
    if (self) {
        MPLogInfo(@"general init");
        if(moPubLoadedInventory == nil) {
            moPubLoadedInventory = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (void)dealloc {
    MPLogInfo(@"general dealloc");
}

#pragma mark Supersonic RV Methods
-(void) initSupersonicSDKWithAppKey: (NSString*) appKey {
    if (NO == isRVInitSuccess) {
        [SupersonicConfiguration getConfiguration].plugin = @"MoPub";
        [SupersonicConfiguration getConfiguration].pluginVersion = @"1.0.1";
        [SupersonicConfiguration getConfiguration].pluginFrameworkVersion = MP_SDK_VERSION;
        
        UIDevice *device = [UIDevice currentDevice];
        NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
        
        [[Supersonic sharedInstance] initRVWithAppKey:appKey withUserId:currentDeviceId];
        [self onLog:@"initSupersonicSDKWithAppKey"];
    }
}


#pragma mark Mopub SupersonicRVCustomEvent Methods
- (void) requestRewardedVideoWithCustomEventInfo:(NSDictionary *)info {
    
    [self onLog:@"requestRewardedVideoWithCustomEventInfo"];
    
    NSString* applicationKey = @"";
    
    // get values from the info dictionary and assign values
    if([info objectForKey:@"placementName"] != nil){
        self.placementName = [info objectForKey:@"placementName"];
    }
    
    if([info objectForKey:@"isTestEnabled"] != nil){
        isRVTestEnabled = [[info objectForKey:@"isTestEnabled"] boolValue];
    }
    
    if([info objectForKey:@"applicationKey"] != nil){
        applicationKey = [info objectForKey:@"applicationKey"];
    }
    
    if([info objectForKey:@"moPubId"] != nil){
        self.moPubId = [info objectForKey:@"moPubId"];
        [moPubLoadedInventory setObject:[NSNumber numberWithBool:YES] forKey:self.moPubId];
    }
    
    [[Supersonic sharedInstance] setRVDelegate:self];
    
    if(applicationKey && applicationKey.length > 0) {
        [self initSupersonicSDKWithAppKey:applicationKey];
        
        if([self hasAdAvailable]) {
            [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
        }
    } else {
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:nil];
    }
}

- (BOOL) hasAdAvailable {
    return [[Supersonic sharedInstance] isAdAvailable];
}

- (void) presentRewardedVideoFromViewController:(UIViewController *)viewController {
    if([self isEmpty:self.placementName]) {
        [[Supersonic sharedInstance] showRVWithViewController:viewController];
    } else {
        [[Supersonic sharedInstance] showRVWithPlacementName:self.placementName];
    }
}

- (void) onLog: (NSString *) log {
    if(isRVTestEnabled) {
        NSLog(@"SupersonicISCustomEvent: %@" , log);
    }
}

- (void) handleCustomEventInvalidated {
    // do nothing
}

- (void) handleAdPlayedForCustomEventNetwork {
    // do nothing
}

#pragma mark Utiles Methods

-(BOOL) isEmpty: (id) thing
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
    
}

#pragma mark Custom Functions

- (NSError*) createErrorWith:(NSString*)description andReason:(NSString*)reaason andSuggestion:(NSString*)suggestion {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(reaason, nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(suggestion, nil)
                               };
    
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}

#pragma mark Supersonic RV Events

/*!
 * @discussion Invoked when initialization of RewardedVideo ad unit has finished successfully.
 */
- (void)supersonicRVInitSuccess {
    [self onLog:@"supersonicRVInitSuccess"];
    isRVInitSuccess = YES;
}

/*!
 * @discussion Invoked when RewardedVideo initialization process has failed.
 *
 *              NSError contains the reason for the failure.
 */
- (void)supersonicRVInitFailedWithError:(NSError *)error {
    [self onLog:@"supersonicRVInitFailedWithError"];
    isRVInitSuccess = NO;
}

/*!
 * @discussion Invoked when there is a change in the ad availability status.
 *
 *              hasAvailableAds - value will change to YES when rewarded videos are available.
 *              You can then show the video by calling showRV(). Value will change to NO when no videos are available.
 */
- (void)supersonicRVAdAvailabilityChanged:(BOOL)hasAvailableAds {
    [self onLog: [NSString stringWithFormat:@"%@ - %i" , @"supersonicRVAdAvailabilityChanged" , hasAvailableAds]];
    NSNumber *isMoPubLoaded = moPubLoadedInventory[self.moPubId];
    if([isMoPubLoaded boolValue]) {
        if(hasAvailableAds){
            [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
        }else {
            [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:nil];
        }
    }
}

/*!
 * @discussion Invoked when the user completed the video and should be rewarded.
 *
 *              If using server-to-server callbacks you may ignore these events and wait for the callback from the Supersonic server.
 *              placementInfo - SupersonicPlacementInfo - an object contains the placement's reward name and amount
 */
- (void)supersonicRVAdRewarded:(SupersonicPlacementInfo*)placementInfo {
    [self onLog:@"supersonicRVAdRewarded"];
    if(placementInfo != NULL)
    {
        NSString * rewardName = [placementInfo rewardName];
        NSNumber * rewardAmount = [placementInfo rewardAmount];
        self.reward = [[MPRewardedVideoReward alloc] initWithCurrencyType:rewardName amount:rewardAmount];
    } else {
        self.reward = [[MPRewardedVideoReward alloc] initWithCurrencyType:kMPRewardedVideoRewardCurrencyTypeUnspecified amount:@(0)];;
    }
    [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:self.reward];
}

/*!
 * @discussion Invoked when an Ad failed to display.
 *
 *          error - NSError which contains the reason for the failure.
 *          The error contains error.code and error.message.
 */
- (void)supersonicRVAdFailedWithError:(NSError *)error {
    [self onLog:@"supersonicRVAdFailedWithError"];
    [self.delegate rewardedVideoDidFailToPlayForCustomEvent: self error:error];
}

/*!
 * @discussion Invoked when the RewardedVideo ad view has opened.
 *
 */
- (void)supersonicRVAdOpened {
    [self onLog:@"supersonicRVAdOpened"];
    [moPubLoadedInventory setObject:[NSNumber numberWithBool:NO] forKey:self.moPubId];
    [self.delegate rewardedVideoWillAppearForCustomEvent:self];
    [self.delegate rewardedVideoDidAppearForCustomEvent:self];
}

/*!
 * @discussion Invoked when the user is about to return to the application after closing the RewardedVideo ad.
 *
 */
- (void)supersonicRVAdClosed {
    [self onLog:@"supersonicRVAdClosed"];
    [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
    [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
    
    self.reward = NULL;
}

/**
 * Note: the events below are not available for all supported Rewarded Video
 * Ad Networks.
 * Check which events are available per Ad Network you choose to include in
 * your build.
 * We recommend only using events which register to ALL Ad Networks you
 * include in your build.
 */


/*!
 * @discussion Invoked when the video ad starts playing.
 *
 *             Available for: AdColony, Vungle, AppLovin, UnityAds
 */
- (void)supersonicRVAdStarted {
    
}

/*!
 * @discussion Invoked when the video ad finishes playing.
 *
 *             Available for: AdColony, Flurry, Vungle, AppLovin, UnityAds.
 */
- (void)supersonicRVAdEnded {
    
}


@end
