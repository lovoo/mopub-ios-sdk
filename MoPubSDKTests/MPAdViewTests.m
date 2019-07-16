//
//  MPAdViewTests.m
//
//  Copyright 2018-2019 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <XCTest/XCTest.h>
#import "MPAdServerKeys.h"
#import "MPAdView.h"
#import "MPAdView+Testing.h"
#import "MPAPIEndpoints.h"
#import "MPBannerAdManager+Testing.h"
#import "MPMockAdServerCommunicator.h"
#import "MPURL.h"
#import "NSURLComponents+Testing.h"
#import "MPImpressionTrackedNotification.h"

static NSTimeInterval const kTestTimeout = 0.5;

@interface MPAdViewTests : XCTestCase
@property (nonatomic, strong) MPAdView * adView;
@property (nonatomic, weak) MPMockAdServerCommunicator * mockAdServerCommunicator;
@end

@implementation MPAdViewTests

- (void)setUp {
    [super setUp];

    self.adView = [[MPAdView alloc] initWithAdUnitId:@"FAKE_AD_UNIT_ID" size:MOPUB_BANNER_SIZE];
    self.adView.adManager.communicator = ({
        MPMockAdServerCommunicator * mock = [[MPMockAdServerCommunicator alloc] initWithDelegate:self.adView.adManager];
        self.mockAdServerCommunicator = mock;
        mock;
    });
}

#pragma mark - Viewability

- (void)testViewabilityQueryParameter {
    // Banner ads should send a viewability query parameter.
    [self.adView loadAd];

    XCTAssertNotNil(self.mockAdServerCommunicator);
    XCTAssertNotNil(self.mockAdServerCommunicator.lastUrlLoaded);

    MPURL * url = [self.mockAdServerCommunicator.lastUrlLoaded isKindOfClass:[MPURL class]] ? (MPURL *)self.mockAdServerCommunicator.lastUrlLoaded : nil;
    XCTAssertNotNil(url);

    NSString * viewabilityValue = [url stringForPOSTDataKey:kViewabilityStatusKey];
    XCTAssertNotNil(viewabilityValue);
    XCTAssertTrue([viewabilityValue isEqualToString:@"1"]);
}

#pragma mark - Impression Level Revenue Data

- (void)testImpressionNotificationWithImpressionData {
    XCTestExpectation * notificationExpectation = [self expectationWithDescription:@"Wait for impression notification"];
    NSString * testAdUnitId = @"FAKE_AD_UNIT_ID";

    // Make notification handler
    id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMPImpressionTrackedNotification
                                                                                object:nil
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification * note){
                                                                                [notificationExpectation fulfill];

                                                                                MPImpressionData * impressionData = note.userInfo[kMPImpressionTrackedInfoImpressionDataKey];
                                                                                XCTAssert([note.object isEqual:self.adView]);
                                                                                XCTAssertNotNil(impressionData);
                                                                                XCTAssert([self.adView.adUnitId isEqualToString:note.userInfo[kMPImpressionTrackedInfoAdUnitIDKey]]);
                                                                                XCTAssert([impressionData.adUnitID isEqualToString:testAdUnitId]);
                                                                            }];

    MPImpressionData * impressionData = [[MPImpressionData alloc] initWithDictionary:@{
                                                                                       kImpressionDataAdUnitIDKey: testAdUnitId
                                                                                       }];

    // Simulate impression
    [self.adView impressionDidFireWithImpressionData:impressionData];

    [self waitForExpectationsWithTimeout:kTestTimeout handler:^(NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Timed out");
        }
    }];

    [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

- (void)testImpressionNotificationWithNoImpressionData {
    XCTestExpectation * notificationExpectation = [self expectationWithDescription:@"Wait for impression notification"];

    // Make notification handler
    id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMPImpressionTrackedNotification
                                                                                object:nil
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification * note){
                                                                                [notificationExpectation fulfill];

                                                                                MPImpressionData * impressionData = note.userInfo[kMPImpressionTrackedInfoImpressionDataKey];
                                                                                XCTAssert([note.object isEqual:self.adView]);
                                                                                XCTAssertNil(impressionData);
                                                                                XCTAssert([self.adView.adUnitId isEqualToString:note.userInfo[kMPImpressionTrackedInfoAdUnitIDKey]]);
                                                                            }];

    // Simulate impression
    [self.adView impressionDidFireWithImpressionData:nil];

    [self waitForExpectationsWithTimeout:kTestTimeout handler:^(NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Timed out");
        }
    }];

    [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

@end
