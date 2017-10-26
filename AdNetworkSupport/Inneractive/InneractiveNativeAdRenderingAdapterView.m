//
//  InneractiveNativeAdRenderingAdapterView.m
//  InneractiveAdSample
//
//  Created by Nikita Fedorenko on 31/12/15.
//  Copyright © 2015 Inneractive. All rights reserved.
//

#import "InneractiveNativeAdRenderingAdapterView.h"
#import <InneractiveAdSDK/InneractiveAdSDK.h>

@interface InneractiveNativeAdRenderingAdapterView ()

@end

@implementation InneractiveNativeAdRenderingAdapterView {}

#pragma mark - Inits

- (instancetype)initWithAdView:(UIView<MPNativeAdRendering> *)adView isDynamicSize:(BOOL)isDynamicSize {
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, adView.frame.size.width, adView.frame.size.height)];
    
    if (self) {
        super.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _adView = adView;
        _isDynamicSize = @(isDynamicSize);
    }
    
    return self;
}

#pragma mark - IaNativeAdRenderingDelegate

- (void)layoutAdAssets:(IaNativeAd *)adObject {
    [self addSubview:self.adView];

    [self layoutSecondaryAssetsOfNativeAd:adObject];
    
    const BOOL hasVideoPlaceholder = [self.adView respondsToSelector:@selector(nativeVideoView)];
    const BOOL hasImagePlaceholder = [self.adView respondsToSelector:@selector(nativeMainImageView)];
    const BOOL isVideoAd = [adObject isVideoAd];
    UIView *mainAssetPlaceholder = nil;
    
    // if ad is video ad AND rendering view class implements 'nativeVideoView', then load video into 'nativeVideoView';
    if (isVideoAd && hasVideoPlaceholder) {
        mainAssetPlaceholder = self.adView.nativeVideoView;
        
        if (hasImagePlaceholder) {
            self.adView.nativeMainImageView.hidden = YES;
        }
    } // else, if ad is video ad, but there is no dedicated video view OR ad is image ad, then load (add subview) video/image into 'nativeMainImageView';
    else if (hasImagePlaceholder) {
        mainAssetPlaceholder = self.adView.nativeMainImageView;
        
        if (hasVideoPlaceholder) {
            self.adView.nativeVideoView.hidden = YES;
        }
    }
    
    mainAssetPlaceholder.hidden = NO;
    mainAssetPlaceholder.userInteractionEnabled = YES;
    
    [self layoutMainAssetInPlaceholder:mainAssetPlaceholder OfNativeAd:adObject];
    
    if (_isDynamicSize) {
        // implement any additional logic, if needed;
    }
}

#pragma mark - Service

- (void)layoutSecondaryAssetsOfNativeAd:(IaNativeAd *)adObject {
    if ([self.adView respondsToSelector:@selector(nativeIconImageView)]) {
        [[InneractiveAdSDK sharedInstance] loadIconIntoImageView:self.adView.nativeIconImageView withNativeAd:adObject];
    }
    
    if ([self.adView respondsToSelector:@selector(nativeTitleTextLabel)]) {
        [[InneractiveAdSDK sharedInstance] loadTitleIntoTitleLabel:self.adView.nativeTitleTextLabel withNativeAd:adObject];
    }
    
    if ([self.adView respondsToSelector:@selector(nativeMainTextLabel)]) {
        [[InneractiveAdSDK sharedInstance] loadBodyTextIntoTitleLabel:self.adView.nativeMainTextLabel withNativeAd:adObject];
    }
    
    if ([self.adView respondsToSelector:@selector(nativeCallToActionTextLabel)]) {
        [[InneractiveAdSDK sharedInstance] loadCallToActionIntoLabel:self.adView.nativeCallToActionTextLabel withNativeAd:adObject];
    }
}

- (void)layoutMainAssetInPlaceholder:(UIView *)mainAssetPlaceholder OfNativeAd:(IaNativeAd *)adObject {
    if (mainAssetPlaceholder) {
        [[InneractiveAdSDK sharedInstance] loadMainAssetIntoView:mainAssetPlaceholder withNativeAd:adObject];
    }
    
    _mainMediaView = mainAssetPlaceholder.subviews.lastObject;
}

#pragma mark - View lifecycle

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize adViewSize = [self.adView sizeThatFits:size];
    
    self.bounds = CGRectMake(0.0f, 0.0f, adViewSize.width, adViewSize.height);
    
    return adViewSize;
}

@end
