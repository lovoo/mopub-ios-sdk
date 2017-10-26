//
//  InneractiveNativeAdAdapter.m
//  InneractiveAdSample
//
//  Created by Nikita Fedorenko on 30/12/15.
//  Copyright © 2015 Inneractive. All rights reserved.
//

#import "InneractiveNativeAdAdapter.h"

#import <InneractiveAdSDK/InneractiveAdSDK.h>

@interface InneractiveNativeAdAdapter () <InneractiveAdDelegate>

@end

@implementation InneractiveNativeAdAdapter {}

// global vars for all instances
static BOOL _inneractiveSDKRefreshInitialFlag = NO;
static BOOL _inneractiveSDKRefreshInitialFlagSet = NO;
static int _inneractiveInstancesCount = 0;

@synthesize properties = _properties;

#pragma mark - Init

- (instancetype)initWithInneractiveNativeAd:(IaNativeAd *)inneractiveNativeAd {
    self = [super init];
    
    if (self) {
        ++_inneractiveInstancesCount;
        
        // preserve initial "auto fetch" setting, if was not set yet
        if (!_inneractiveSDKRefreshInitialFlagSet) {
            _inneractiveSDKRefreshInitialFlagSet = YES;
            _inneractiveSDKRefreshInitialFlag = [InneractiveAdSDK sharedInstance].sdkConfig.disableAutoFetch;
        }
        
        // anyway disable "auto fetch"
        [[InneractiveAdSDK sharedInstance].sdkConfig setDisableAutoFetch:YES];
        
        // taking responsibility of Inneractive Ads from now, because custom event class will be deallocated
        inneractiveNativeAd.delegate = self;
        
        _inneractiveNativeAd = inneractiveNativeAd;
    }
    
    return self;
}

#pragma mark - MPNativeAdAdapter

- (NSURL *)defaultActionURL {
    return nil;
}

- (UIView *)mainMediaView {
    return _mainMediaView;
}

- (BOOL)enableThirdPartyClickTracking {
    return YES;
}

#pragma mark - InneractiveAdDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    UIViewController *viewController = [self.delegate viewControllerForPresentingModalView];
    
    return viewController;
}

/**
 * 'InneractiveAdFailedWithError:withAdView:' event can be called, even after 'InneractiveAdLoaded:' was called,
 * in case there is video and buffering timeout occured; */

- (void)InneractiveAdFailedWithError:(NSError *)error withAdView:(IaAd *)ad {
    // treat buffering timeout
}

- (void)InneractiveAdClicked:(IaAd *)ad {
    [self.delegate nativeAdDidClick:self];
}

- (void)InneractiveAdWillLogImpression:(IaAd *)ad {
    [self.delegate nativeAdWillLogImpression:self];
}

- (void)InneractiveAdAppShouldSuspend:(IaAd *)ad {
    [self.delegate nativeAdWillPresentModalForAdapter:self];
}

- (void)InneractiveAdAppShouldResume:(IaAd *)ad {
    [self.delegate nativeAdDidDismissModalForAdapter:self];
}

- (void)InneractiveAdWillOpenExternalApp:(IaAd *)ad {
    [self.delegate nativeAdWillLeaveApplicationFromAdapter:self];
}

- (void)InneractiveVideoCompleted:(IaAd *)ad {
    
}

#pragma mark - Memory management

- (void)dealloc {
    --_inneractiveInstancesCount;

    // if is last instance and "auto fetch" setting was changed, restore it
    if ((_inneractiveInstancesCount == 0) && (_inneractiveSDKRefreshInitialFlag != [InneractiveAdSDK sharedInstance].sdkConfig.disableAutoFetch)) {
        [[InneractiveAdSDK sharedInstance].sdkConfig setDisableAutoFetch:_inneractiveSDKRefreshInitialFlag];
    }
}

@end
