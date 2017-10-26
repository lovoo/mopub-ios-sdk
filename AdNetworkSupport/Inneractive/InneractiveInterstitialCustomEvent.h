//
//  InneractiveInterstitialCustomEvent.h
//  InneractiveAdSDK
//
//  Created by Inneractive.
//  Copyright (c) 2014 Inneractive. All rights reserved.
//

#import "MPInterstitialCustomEvent.h"
#import <InneractiveAdSDK/InneractiveAdSDK.h>

/**
 *  @brief Interstitial Custom Event Class for MoPub SDK.
 *  @discussion Use to implement mediation with Inneractive Interstitial Ads.
 */
@interface InneractiveInterstitialCustomEvent : MPInterstitialCustomEvent <InneractiveAdDelegate>

/**
 *  @brief The view controller, that will present Inneractive interstitial ad.
 */
@property (nonatomic, strong) UIViewController *interstitialRootViewController;

/**
 *  @brief Inneractive IaAdView instance.
 *  @discussion A interstitial ad, that will be rendered on top of the MoPub ad.
 */
@property (nonatomic, strong) IaAdView *interstitialAdView;

@end
