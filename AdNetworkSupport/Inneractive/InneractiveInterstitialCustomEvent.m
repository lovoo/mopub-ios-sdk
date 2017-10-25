//
//  InneractiveInterstitialCustomEvent.m
//  InneractiveAdSDK
//
//  Created by Inneractive.
//  Copyright (c) 2014 Inneractive. All rights reserved.
//

#import "InneractiveInterstitialCustomEvent.h"
#import "MPLogging.h"
#import "InneractiveCustomEventsKeys.h"

@implementation InneractiveInterstitialCustomEvent {}

/**
 *  @brief Called when the MoPub SDK requires a new interstitial ad.
 *  @discussion The Inneractive interstitial ad will be created in this method.
 *
 *  @param info Info dictionary - a JSON object defined at MoPub console.
 */
- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info {
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

    if (!self.interstitialAdView) {
        self.interstitialAdView = [[IaAdView alloc] initWithAppId:appID adType:IaAdType_Interstitial delegate:self];
    }
    
    if (keywords) {
        self.interstitialAdView.adConfig.adKeyWords = keywords;
    } else {
        // Here you can configure your keywords, e.g:
        // self.bannerAdView.adConfig.adKeyWords = <KEYWORDS SEPARATED BY COMMA>;
        // More info. about the different configuration parameters can be found here: https://confluence.inner-active.com/display/DevWiki/iOS+SDK+guidelines
    }
    
    if (self.delegate.location) {
        self.interstitialAdView.adConfig.location = self.delegate.location;
    }
    
    
    [[InneractiveAdSDK sharedInstance] loadAd:self.interstitialAdView];
}

/**
 *  @brief Shows the interstitial ad.
 *
 *  @param rootViewController The view controller, that will present Inneractive interstitial ad.
 */
- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if (rootViewController) {
        self.interstitialRootViewController = rootViewController;
        [[InneractiveAdSDK sharedInstance] showInterstitialAd:self.interstitialAdView];
    } else {
        MPLogError(@"ERROR: InneractiveInterstitialCustomEvent::showInterstitialFromRootViewController - rootViewController supplied is nil.");
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

#pragma mark - InneractiveAdDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    return self.interstitialRootViewController;
}

- (void)InneractiveAdLoaded:(IaAd *)ad {
    NSLog(@"InneractiveAdLoaded MOPUB HANDLER");
    
    [self.delegate interstitialCustomEvent:self didLoadAd:ad];
}

- (void)InneractiveAdFailedWithError:(NSError *)error withAdView:(IaAd *)ad {
    MPLogError(@"InneractiveAdFailed MOPUB HANDLER Error: %@ for adView: %@", error, ad);
    
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
}

- (void)InneractiveInterstitialAdWillShow:(IaAdView *)adView {
    MPLogInfo(@"InneractiveInterstitialAdWillShow MOPUB HANDLER");
    
    [self.delegate interstitialCustomEventWillAppear:self];
}

- (void)InneractiveInterstitialAdDidShow:(IaAdView *)adView {
    MPLogInfo(@"InneractiveInterstitialAdDidShow MOPUB HANDLER");
    
    [self.delegate interstitialCustomEventDidAppear:self];
}

- (void)InneractiveAdClicked:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdClicked MOPUB HANDLER");
    
    [self.delegate interstitialCustomEventDidReceiveTapEvent:self];
}

- (void)InneractiveInterstitialAdDismissed:(IaAdView *)adView {
    MPLogInfo(@"InneractiveInterstitialAdDismissed MOPUB HANDLER - Interstitial close button was pressed.");
    
    [self.delegate interstitialCustomEventWillDisappear:self];
    [self.delegate interstitialCustomEventDidDisappear:self];
}

- (void)InneractiveAdWillOpenExternalApp:(IaAd *)ad {
    MPLogInfo(@"InneractiveAdWillOpenExternalApp MOPUB HANDLER");
    
    [self.delegate interstitialCustomEventWillLeaveApplication:self];
}

#pragma mark - Memory management

- (void)dealloc {
    [[InneractiveAdSDK sharedInstance] removeAd:_interstitialAdView];
}

@end
