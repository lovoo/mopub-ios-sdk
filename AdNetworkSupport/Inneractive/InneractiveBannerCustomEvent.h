//
//  InneractiveBannerCustomEvent.h
//  InneractiveAdSDK
//
//  Created by Inneractive.
//  Copyright (c) 2014 Inneractive. All rights reserved.
//

#import "MPBannerCustomEvent.h"
#import <InneractiveAdSDK/InneractiveAdSDK.h>

/**
 *  @brief Banner Custom Event Class for MoPub SDK.
 *  @discussion Use to implement mediation with Inneractive Banner Ads.
 */
@interface InneractiveBannerCustomEvent : MPBannerCustomEvent <InneractiveAdDelegate>

/**
 *  @brief Inneractive IaAdView instance.
 *  @discussion A banner/rectangle ad, that will be rendered on top of the MoPub ad.
 */
@property (nonatomic, strong) IaAdView *bannerAdView;

@end
