//
//  InneractiveBannerCustomEvent.m
//  InneractiveAdSDK
//
//  Created by Inneractive.
//  Copyright (c) 2014 Inneractive. All rights reserved.
//

#import "InneractiveBannerCustomEvent.h"
#import "MPConstants.h"
#import "MPLogging.h"
#import "MPInstanceProvider.h"
#import "InneractiveCustomEventsKeys.h"

/**
 *  @brief Inneractive category for MoPub instance provider.
 */
@interface MPInstanceProvider (IABannerInstanceProvider)

/**
 *  @brief Creates Inneractive ad in a way like MoPub ad is created.
 *
 *  @param appId    App ID.
 *  @param adSize   Ad size, defined by MoPub.
 *  @param delegate Inneractive ad delegate.
 *
 *  @return IaAdView instance.
 */
- (IaAdView *)buildIABannerWithAppId:(NSString *)appId adSize:(CGSize)adSize delegate:(id <InneractiveAdDelegate>)delegate;

/**
 *  @brief Converts MoPub ad size to Inneractive ad type.
 *
 *  @param size Mopub ad size.
 *
 *  @return Inneractive ad type.
 */
- (IaAdType)convertSizeToInneractiveAdType:(CGSize)size;

@end

@implementation MPInstanceProvider (IABannerInstanceProvider)

- (IaAdView *)buildIABannerWithAppId:(NSString *)appId adSize:(CGSize)adSize delegate:(id <InneractiveAdDelegate>)delegate {
    IaAdView *adView = [[IaAdView alloc] initWithAppId:appId
                                                adType:[self convertSizeToInneractiveAdType:adSize]
                                              delegate:delegate];
    
    return adView;
}
            
- (IaAdType)convertSizeToInneractiveAdType:(CGSize)size {
    if (CGSizeEqualToSize(size, MOPUB_BANNER_SIZE) || CGSizeEqualToSize(size, MOPUB_LEADERBOARD_SIZE)) {
        return IaAdType_Banner;
    } else if (CGSizeEqualToSize(size, MOPUB_MEDIUM_RECT_SIZE)) {
        return IaAdType_Rectangle;
    } else {
        MPLogWarn(@"Ad size is not supported by inneractive, requesting a Banner ad.");
        return IaAdType_Banner;
    }
}

@end

@implementation InneractiveBannerCustomEvent {}

/**
 *  @brief Called when the MoPub SDK requires a new banner ad.
 *  @discussion The Inneractive banner/rectangle ad will be created in this method.
 *
 *  @param size Ad size.
 *  @param info Info dictionary - a JSON object defined at MoPub console.
 */
- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info {
    NSString *appID = kInneractiveDefaultAppID;
    NSString *keywords = nil;
    
    if (info && [info isKindOfClass:NSDictionary.class] && info.count) {
        NSString *receivedAppID = info[kInneractiveAppIDKey];
        NSString *receivedKeywords = info[kInneractiveKeywords];
        
        if (receivedAppID && [receivedAppID isKindOfClass:NSString.class] && receivedAppID.length) {
            appID = receivedAppID;
        }
        
        if (receivedKeywords && [receivedKeywords isKindOfClass:NSString.class] && receivedKeywords.length) {
            keywords = receivedKeywords;
        }
    }
    
    [[InneractiveAdSDK sharedInstance] setAdMediationType:IaAdMediationType_Mopub];

    self.bannerAdView = [[MPInstanceProvider sharedProvider] buildIABannerWithAppId:appID adSize:size delegate:self];
    
    if (keywords) {
        self.bannerAdView.adConfig.adKeyWords = keywords;
    } else {
        // Here you can configure your keywords, e.g:
        // self.bannerAdView.adConfig.adKeyWords = <KEYWORDS SEPARATED BY COMMA>;
        // More info. about the different configuration parameters can be found here: https://confluence.inner-active.com/display/DevWiki/iOS+SDK+guidelines
    }
    
    if (self.delegate.location) {
        self.bannerAdView.adConfig.location = self.delegate.location;
    }
    

    [[InneractiveAdSDK sharedInstance] loadAd:self.bannerAdView];
}

#pragma mark - InneractiveAdDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    return self.delegate.viewControllerForPresentingModalView;
}

- (void)InneractiveAdLoaded:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdLoaded");
    
    [self.delegate bannerCustomEvent:self didLoadAd:ad];
}

- (void)InneractiveAdFailedWithError:(NSError *)error withAdView:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdFailed Error: %@ for adView: %@", error, ad);
    
	[self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
}

- (void)InneractiveAdClicked:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdClicked");
}

- (void)InneractiveAdDidExpand:(IaAdView *)adView toFrame:(NSValue *)frameAsValue {
    MPLogInfo(@"InneractiveAdDidExpand to frame: %@", frameAsValue);
}

- (void)InneractiveAdAppShouldSuspend:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdAppShouldSuspend");
    
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)InneractiveAdAppShouldResume:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdAppShouldResume");
    
    [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)InneractiveAdWillOpenExternalApp:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdWillOpenExternalApp");
    
    [self.delegate bannerCustomEventWillLeaveApplication:self];
}

#pragma mark - Memory management

- (void)dealloc {
    [[InneractiveAdSDK sharedInstance] removeAd:_bannerAdView];
}

@end
