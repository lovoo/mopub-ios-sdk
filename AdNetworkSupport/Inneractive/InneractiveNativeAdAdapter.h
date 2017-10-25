//
//  InneractiveNativeAdAdapter.h
//  InneractiveAdSample
//
//  Created by Nikita Fedorenko on 30/12/15.
//  Copyright © 2015 Inneractive. All rights reserved.
//

#import "MPNativeAdAdapter.h"

@class IaNativeAd;

@interface InneractiveNativeAdAdapter : NSObject <MPNativeAdAdapter>

@property (nonatomic, weak) id<MPNativeAdAdapterDelegate> delegate;

@property (nonatomic, strong) IaNativeAd *inneractiveNativeAd;
@property (nonatomic, weak) UIView *mainMediaView;

- (instancetype)initWithInneractiveNativeAd:(IaNativeAd *)inneractiveNativeAd;

@end
