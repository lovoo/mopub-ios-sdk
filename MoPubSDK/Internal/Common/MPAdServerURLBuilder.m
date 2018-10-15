//
//  MPAdServerURLBuilder.m
//
//  Copyright 2018 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPAdServerURLBuilder.h"

#import <CoreLocation/CoreLocation.h>

#import "MPAdvancedBiddingManager.h"
#import "MPAdServerKeys.h"
#import "MPConstants.h"
#import "MPGeolocationProvider.h"
#import "MPGlobal.h"
#import "MPIdentityProvider.h"
#import "MPCoreInstanceProvider+MRAID.h"
#import "MPReachabilityManager.h"
#import "MPAPIEndpoints.h"
#import "MPViewabilityTracker.h"
#import "NSString+MPAdditions.h"
#import "NSString+MPConsentStatus.h"
#import "MPConsentManager.h"

static NSString * const kMoPubInterfaceOrientationPortrait = @"p";
static NSString * const kMoPubInterfaceOrientationLandscape = @"l";
static NSInteger const kAdSequenceNone = -1;

@interface MPAdServerURLBuilder ()

/**
 * Builds an NSMutableDictionary with all generic URL parameters and their values. The `id` URL parameter is gathered from
 * the `idParameter` method parameter because it has different uses depending on the URL. This base set of parameters
 * includes the following:
 * - ID Parameter (`id`)
 * - Server API Version Used (`v`)
 * - SDK Version (`nv`)
 * - Application Version (`av`)
 * - GDPR Region Applicable (`gdpr_applies`)
 * - Current Consent Status (`current_consent_status`)
 * - Limit Ad Tracking Status (`dnt`)
 * - Bundle Identifier (`bundle`)
 * - IF AVAILABLE: Consented Privacy Policy Version (`consented_privacy_policy_version`)
 * - IF AVAILABLE: Consented Vendor List Version (`consented_vendor_list_version`)
 */
+ (NSMutableDictionary *)baseParametersDictionaryWithIDParameter:(NSString *)idParameter;

/**
 * Builds an NSMutableDictionary with all generic URL parameters above and their values, but with the addition of IDFA.
 * If @c usingIDFAForConsent is @c YES, the IDFA will be gathered from MPConsentManager (which may be nil without
 * consent). Otherwise, the IDFA will be taken from MPIdentityProvider, which will always have a value, but may be
 * MoPub's value.
 */
+ (NSMutableDictionary *)baseParametersDictionaryWithIDFAUsingIDFAForConsent:(BOOL)usingIDFAForConsent
                                                             withIDParameter:(NSString *)idParameter;

@end

@implementation MPAdServerURLBuilder

+ (MPURL *)URLWithEndpointPath:(NSString *)endpointPath postData:(NSDictionary *)parameters {
    // Build the full URL string
    NSURLComponents * components = [MPAPIEndpoints baseURLComponentsWithPath:endpointPath];
    return [MPURL URLWithComponents:components postData:parameters];
}

+ (NSMutableDictionary *)baseParametersDictionaryWithIDParameter:(NSString *)idParameter {
    MPConsentManager * manager = MPConsentManager.sharedManager;
    NSMutableDictionary * queryParameters = [NSMutableDictionary dictionary];

    // REQUIRED: ID Parameter (used for different things depending on which URL, take from method parameter)
    queryParameters[kAdServerIDKey] = idParameter;

    // REQUIRED: Server API Version
    queryParameters[kServerAPIVersionKey] = MP_SERVER_VERSION;

    // REQUIRED: SDK Version
    queryParameters[kSDKVersionKey] = MP_SDK_VERSION;

    // REQUIRED: Application Version
    queryParameters[kApplicationVersionKey] = [self applicationVersion];

    // REQUIRED: GDPR region applicable
    if (manager.isGDPRApplicable != MPBoolUnknown) {
        queryParameters[kGDPRAppliesKey] = manager.isGDPRApplicable > 0 ? @"1" : @"0";
    }

    // REQUIRED: GDPR applicable was forced
    queryParameters[kForceGDPRAppliesKey] = manager.forceIsGDPRApplicable ? @"1" : @"0";

    // REQUIRED: Current consent status
    queryParameters[kCurrentConsentStatusKey] = [NSString stringFromConsentStatus:manager.currentStatus];

    // REQUIRED: DNT, Bundle
    queryParameters[kDoNotTrackIdKey] = [MPIdentityProvider advertisingTrackingEnabled] ? nil : @"1";
    queryParameters[kBundleKey] = [[NSBundle mainBundle] bundleIdentifier];

    // OPTIONAL: Consented versions
    queryParameters[kConsentedPrivacyPolicyVersionKey] = manager.consentedPrivacyPolicyVersion;
    queryParameters[kConsentedVendorListVersionKey] = manager.consentedVendorListVersion;

    return queryParameters;
}

+ (NSMutableDictionary *)baseParametersDictionaryWithIDFAUsingIDFAForConsent:(BOOL)usingIDFAForConsent
                                                             withIDParameter:(NSString *)idParameter {
    MPConsentManager * manager = MPConsentManager.sharedManager;
    NSMutableDictionary * queryParameters = [self baseParametersDictionaryWithIDParameter:idParameter];

    // OPTIONAL: IDFA if available
    if (usingIDFAForConsent) {
        queryParameters[kIdfaKey] = manager.ifaForConsent;
    } else {
        queryParameters[kIdfaKey] = [MPIdentityProvider identifier];
    }

    return queryParameters;
}

+ (NSString *)applicationVersion {
    static NSString * gApplicationVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gApplicationVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    });

    return gApplicationVersion;
}

@end

@implementation MPAdServerURLBuilder (Ad)

+ (MPURL *)URLWithAdUnitID:(NSString *)adUnitID
                  keywords:(NSString *)keywords
          userDataKeywords:(NSString *)userDataKeywords
                  location:(CLLocation *)location
{
    return [self URLWithAdUnitID:adUnitID
                        keywords:keywords
                userDataKeywords:userDataKeywords
                        location:location
                   desiredAssets:nil
                     viewability:YES];
}

+ (MPURL *)URLWithAdUnitID:(NSString *)adUnitID
                  keywords:(NSString *)keywords
          userDataKeywords:(NSString *)userDataKeywords
                  location:(CLLocation *)location
             desiredAssets:(NSArray *)assets
               viewability:(BOOL)viewability
{


    return [self URLWithAdUnitID:adUnitID
                        keywords:keywords
                userDataKeywords:userDataKeywords
                        location:location
                   desiredAssets:assets
                      adSequence:kAdSequenceNone
                     viewability:viewability];
}

+ (MPURL *)URLWithAdUnitID:(NSString *)adUnitID
                  keywords:(NSString *)keywords
          userDataKeywords:(NSString *)userDataKeywords
                  location:(CLLocation *)location
             desiredAssets:(NSArray *)assets
                adSequence:(NSInteger)adSequence
               viewability:(BOOL)viewability
{
    // In the event that the `adUnitIdUsedForConsent` from `MPConsentManager` is still `nil`,
    // we should populate it with this `adUnitId`. This is to cover the edge case where the
    // publisher does not explcitily initialize the SDK via `initializeSdkWithConfiguration:completion:`.
    if (adUnitID != nil && MPConsentManager.sharedManager.adUnitIdUsedForConsent == nil) {
        MPConsentManager.sharedManager.adUnitIdUsedForConsent = adUnitID;
    }

    NSMutableDictionary * queryParams = [self baseParametersDictionaryWithIDFAUsingIDFAForConsent:NO
                                                                                  withIDParameter:adUnitID];

    queryParams[kOrientationKey]                = [self orientationValue];
    queryParams[kScaleFactorKey]                = [self scaleFactorValue];
    queryParams[kTimeZoneKey]                   = [self timeZoneValue];
    queryParams[kIsMRAIDEnabledSDKKey]          = [self isMRAIDEnabledSDKValue];
    queryParams[kConnectionTypeKey]             = [self connectionTypeValue];
    queryParams[kCarrierNameKey]                = [self carrierNameValue];
    queryParams[kISOCountryCodeKey]             = [self isoCountryCodeValue];
    queryParams[kMobileNetworkCodeKey]          = [self mobileNetworkCodeValue];
    queryParams[kMobileCountryCodeKey]          = [self mobileCountryCodeValue];
    queryParams[kDeviceNameKey]                 = [self deviceNameValue];
    queryParams[kDesiredAdAssetsKey]            = [self desiredAdAssetsValue:assets];
    queryParams[kAdSequenceKey]                 = [self adSequenceValue:adSequence];
    queryParams[kScreenResolutionWidthKey]      = [self physicalScreenResolutionWidthValue];
    queryParams[kScreenResolutionHeightKey]     = [self physicalScreenResolutionHeightValue];
    queryParams[kAppTransportSecurityStatusKey] = [self appTransportSecurityStatusValue];
    queryParams[kKeywordsKey]                   = [self keywordsValue:keywords];
    queryParams[kUserDataKeywordsKey]           = [self userDataKeywordsValue:userDataKeywords];
    queryParams[kViewabilityStatusKey]          = [self viewabilityStatusValue:viewability];
    queryParams[kAdvancedBiddingKey]            = [self advancedBiddingValue];
    [queryParams addEntriesFromDictionary:[self locationInformationDictionary:location]];

    return [self URLWithEndpointPath:MOPUB_API_PATH_AD_REQUEST postData:queryParams];
}

+ (NSString *)orientationValue
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    return UIInterfaceOrientationIsPortrait(orientation) ?
    kMoPubInterfaceOrientationPortrait : kMoPubInterfaceOrientationLandscape;
}

+ (NSString *)scaleFactorValue
{
    return [NSString stringWithFormat:@"%.1f", MPDeviceScaleFactor()];
}

+ (NSString *)timeZoneValue
{
    static NSDateFormatter *formatter;
    @synchronized(self)
    {
        if (!formatter) formatter = [[NSDateFormatter alloc] init];
    }
    [formatter setDateFormat:@"Z"];
    NSDate *today = [NSDate date];
    return [formatter stringFromDate:today];
}

+ (NSString *)isMRAIDEnabledSDKValue
{
    BOOL isMRAIDEnabled = [[MPCoreInstanceProvider sharedProvider] isMraidJavascriptAvailable] &&
                          NSClassFromString(@"MPMRAIDBannerCustomEvent") != Nil &&
                          NSClassFromString(@"MPMRAIDInterstitialCustomEvent") != Nil;
    return isMRAIDEnabled ? @"1" : nil;
}

+ (NSString *)connectionTypeValue
{
    return [NSString stringWithFormat:@"%ld", (long)MPReachabilityManager.sharedManager.currentStatus];
}

+ (NSString *)carrierNameValue
{
    NSString *carrierName = [[[MPCoreInstanceProvider sharedProvider] sharedCarrierInfo] objectForKey:@"carrierName"];
    return carrierName;
}

+ (NSString *)isoCountryCodeValue
{
    NSString *code = [[[MPCoreInstanceProvider sharedProvider] sharedCarrierInfo] objectForKey:@"isoCountryCode"];
    return code;
}

+ (NSString *)mobileNetworkCodeValue
{
    NSString *code = [[[MPCoreInstanceProvider sharedProvider] sharedCarrierInfo] objectForKey:@"mobileNetworkCode"];
    return code;
}

+ (NSString *)mobileCountryCodeValue
{
    NSString *code = [[[MPCoreInstanceProvider sharedProvider] sharedCarrierInfo] objectForKey:@"mobileCountryCode"];
    return code;
}

+ (NSString *)deviceNameValue
{
    NSString *deviceName = [[UIDevice currentDevice] mp_hardwareDeviceName];
    return deviceName;
}

+ (NSString *)desiredAdAssetsValue:(NSArray *)assets
{
    NSString *concatenatedAssets = [assets componentsJoinedByString:@","];
    return [concatenatedAssets length] ? concatenatedAssets : nil;
}

+ (NSString *)adSequenceValue:(NSInteger)adSequence
{
    return (adSequence >= 0) ? [NSString stringWithFormat:@"%ld", (long)adSequence] : nil;
}

+ (NSString *)physicalScreenResolutionWidthValue
{
    return [NSString stringWithFormat:@"%.0f", MPScreenResolution().width];
}

+ (NSString *)physicalScreenResolutionHeightValue
{
    return [NSString stringWithFormat:@"%.0f", MPScreenResolution().height];
}

+ (NSString *)appTransportSecurityStatusValue
{
    return [NSString stringWithFormat:@"%@", @([[MPCoreInstanceProvider sharedProvider] appTransportSecuritySettings])];
}

+ (NSString *)keywordsValue:(NSString *)keywords
{
    return keywords;
}

+ (NSString *)userDataKeywordsValue:(NSString *)userDataKeywords
{
    // Avoid sending user data keywords if we are not allowed to collect personal info
    if (![MPConsentManager sharedManager].canCollectPersonalInfo) {
        return nil;
    }

    return userDataKeywords;
}

+ (NSString *)viewabilityStatusValue:(BOOL)isViewabilityEnabled {
    if (!isViewabilityEnabled) {
        return nil;
    }

    return [NSString stringWithFormat:@"%d", (int)[MPViewabilityTracker enabledViewabilityVendors]];
}

+ (NSString *)advancedBiddingValue {
    // Opted out of advanced bidding, no query parameter should be sent.
    if (![MPAdvancedBiddingManager sharedManager].advancedBiddingEnabled) {
        return nil;
    }

    // No JSON at this point means that no advanced bidders were initialized.
    NSString * tokens = MPAdvancedBiddingManager.sharedManager.bidderTokensJson;
    if (tokens == nil) {
        return nil;
    }

    return tokens;
}

+ (NSDictionary *)locationInformationDictionary:(CLLocation *)location {
    if (![MPConsentManager.sharedManager canCollectPersonalInfo] || !location) {
        return @{};
    }

    NSMutableDictionary *locationDict = [NSMutableDictionary dictionary];

    CLLocation *bestLocation = location;
    CLLocation *locationFromProvider = [[[MPCoreInstanceProvider sharedProvider] sharedMPGeolocationProvider] lastKnownLocation];

    if (locationFromProvider) {
        bestLocation = locationFromProvider;
    }

    if (bestLocation && bestLocation.horizontalAccuracy >= 0) {
        locationDict[kLocationLatitudeLongitudeKey] = [NSString stringWithFormat:@"%@,%@",
                                                       @(bestLocation.coordinate.latitude),
                                                       @(bestLocation.coordinate.longitude)];
        if (bestLocation.horizontalAccuracy) {
            locationDict[kLocationHorizontalAccuracy] = [NSString stringWithFormat:@"%@", @(bestLocation.horizontalAccuracy)];
        }

        if (bestLocation == locationFromProvider) {
            locationDict[kLocationIsFromSDK] = @"1";
        }

        NSTimeInterval locationLastUpdatedMillis = [[NSDate date] timeIntervalSinceDate:bestLocation.timestamp] * 1000.0;
        locationDict[kLocationLastUpdatedMilliseconds] = [NSString stringWithFormat:@"%.0f", locationLastUpdatedMillis];
    }

    return locationDict;
}

@end

@implementation MPAdServerURLBuilder (Open)

+ (NSURL *)conversionTrackingURLForAppID:(NSString *)appID {
    return [self openEndpointURLWithIDParameter:appID isSessionTracking:NO];
}

+ (MPURL *)sessionTrackingURL {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [self openEndpointURLWithIDParameter:bundleIdentifier isSessionTracking:YES];
}

+ (MPURL *)openEndpointURLWithIDParameter:(NSString *)idParameter isSessionTracking:(BOOL)isSessionTracking {
    NSMutableDictionary * queryParameters = [self baseParametersDictionaryWithIDFAUsingIDFAForConsent:NO
                                                                                      withIDParameter:idParameter];

    // OPTIONAL: Include Session Tracking Parameter if needed
    if (isSessionTracking) {
        queryParameters[kOpenEndpointSessionTrackingKey] = @"1";
    }

    return [self URLWithEndpointPath:MOPUB_API_PATH_OPEN postData:queryParameters];
}

@end

@implementation MPAdServerURLBuilder (Consent)

#pragma mark - Consent URLs

+ (MPURL *)consentSynchronizationUrl {
    MPConsentManager * manager = MPConsentManager.sharedManager;

    // REQUIRED: Ad unit ID for consent may be empty if the publisher
    // never initialized the SDK.
    NSMutableDictionary * postData = [self baseParametersDictionaryWithIDFAUsingIDFAForConsent:YES
                                                                               withIDParameter:manager.adUnitIdUsedForConsent];

    // OPTIONAL: Last synchronized consent status, last changed reason,
    // last changed timestamp in milliseconds
    postData[kLastSynchronizedConsentStatusKey] = manager.lastSynchronizedStatus;
    postData[kConsentChangedReasonKey] = manager.lastChangedReason;
    postData[kLastChangedMsKey] = manager.lastChangedTimestampInMilliseconds > 0 ? [NSString stringWithFormat:@"%llu", (unsigned long long)manager.lastChangedTimestampInMilliseconds] : nil;

    // OPTIONAL: Cached IAB Vendor List Hash Key
    postData[kCachedIabVendorListHashKey] = manager.iabVendorListHash;

    // OPTIONAL: Server extras
    postData[kExtrasKey] = manager.extras;

    // OPTIONAL: Force GDPR appliciability has changed
    postData[kForcedGDPRAppliesChangedKey] = manager.isForcedGDPRAppliesTransition ? @"1" : nil;

    return [self URLWithEndpointPath:MOPUB_API_PATH_CONSENT_SYNC postData:postData];
}

+ (MPURL *)consentDialogURL {
    MPConsentManager * manager = MPConsentManager.sharedManager;

    // REQUIRED: Ad unit ID for consent; may be empty if the publisher
    // never initialized the SDK.
    NSMutableDictionary * postData = [self baseParametersDictionaryWithIDParameter:manager.adUnitIdUsedForConsent];

    // REQUIRED: Language
    postData[kLanguageKey] = manager.currentLanguageCode;

    return [self URLWithEndpointPath:MOPUB_API_PATH_CONSENT_DIALOG postData:postData];
}

@end

@implementation MPAdServerURLBuilder (Native)

+ (MPURL *)nativePositionUrlForAdUnitId:(NSString *)adUnitId {
    // No ad unit ID
    if (adUnitId == nil) {
        return nil;
    }

    NSDictionary * queryItems = [self baseParametersDictionaryWithIDFAUsingIDFAForConsent:NO withIDParameter:adUnitId];
    return [self URLWithEndpointPath:MOPUB_API_PATH_NATIVE_POSITIONING postData:queryItems];
}

@end

@implementation MPAdServerURLBuilder (Rewarded)

+ (MPURL *)rewardedCompletionUrl:(NSString *)sourceUrl
                  withCustomerId:(NSString *)customerId
                      rewardType:(NSString *)rewardType
                    rewardAmount:(NSNumber *)rewardAmount
                 customEventName:(NSString *)customEventName
                  additionalData:(NSString *)additionalData {

    NSURLComponents * components = [NSURLComponents componentsWithString:sourceUrl];

    // Build the additional query parameters to be appended to the existing set.
    NSMutableDictionary<NSString *, NSString *> * postData = [NSMutableDictionary dictionary];

    // REQUIRED: Rewarded APIVersion
    postData[kServerAPIVersionKey] = MP_REWARDED_API_VERSION;

    // REQUIRED: SDK Version
    postData[kSDKVersionKey] = MP_SDK_VERSION;

    // OPTIONAL: Customer ID
    if (customerId != nil && customerId.length > 0) {
        postData[kCustomerIdKey] = customerId;
    }

    // OPTIONAL: Rewarded currency and amount
    if (rewardType != nil && rewardType.length > 0 && rewardAmount != nil) {
        postData[kRewardedCurrencyNameKey] = rewardType;
        postData[kRewardedCurrencyAmountKey] = [NSString stringWithFormat:@"%i", rewardAmount.intValue];
    }

    // OPTIONAL: Rewarded custom event name
    if (customEventName != nil) {
        postData[kRewardedCustomEventNameKey] = customEventName;
    }

    // OPTIONAL: Additional publisher data
    if (additionalData != nil) {
        postData[kRewardedCustomDataKey] = additionalData;
    }

    return [MPURL URLWithComponents:components postData:postData];
}

@end

