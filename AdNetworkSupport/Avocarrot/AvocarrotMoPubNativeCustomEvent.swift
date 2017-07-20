//
//  AvocarrotMoPubNativeCustomEvent.swift
//  AvocarrotSDKAdapters
//
//  Created by  Glispa GmbH on 15/06/16.
//  Copyright © 2016  Glispa GmbH. All rights reserved.
//

import Foundation
import MoPub
import AvocarrotNativeAssets

@objc(AvocarrotMoPubNativeCustomEvent)
open class AvocarrotMoPubNativeCustomEvent: MPNativeCustomEvent {

	fileprivate var avocarrotCustomAdapter: AvocarrotMoPubCustomAdapter?

	/** @name Requesting a Native Ad */

	/**
	 * Called when the MoPub SDK requires a new native ad.
	 *
	 * When the MoPub SDK receives a response indicating it should load a custom event, it will send
	 * this message to your custom event class. Your implementation should load a native ad from a
	 * third-party ad network.
	 *
	 * @param info A dictionary containing additional custom data associated with a given custom event
	 * request. This data is configurable on the MoPub website, and may be used to pass dynamic
	 * information, such as publisher IDs.
	 */
	open override func requestAd(withCustomEventInfo info: [AnyHashable: Any]!) {

		guard let adUnit = (info["adUnit" as NSObject] as? String) else { reportError("No AdUnit!"); return }

        AvocarrotSDK.logEnabled = true
        AvocarrotSDK.shared.loadNativeAd(withAdUnitId: adUnit, success: {[weak self] (nativeAd: AVONativeAssets) -> UIView? in
            guard let sSelf = self else {return nil}

            nativeAd.onImpression({[weak self] in
                guard let sSelf = self else {return}
                sSelf.avocarrotCustomAdapter?.registerImpressionToMopub()
            })
            .onClick({[weak self] in
                guard let sSelf = self else {return}
                sSelf.avocarrotCustomAdapter?.registerClickToMopub()
            })
            .onLeftApplication({[weak self] in
                guard let sSelf = self else {return}
                sSelf.avocarrotCustomAdapter?.registerFinishHandlingClickToMopub()
            })

            sSelf.avocarrotCustomAdapter = AvocarrotMoPubCustomAdapter(ad: nativeAd)
            sSelf.preloadAdImages(forNativeAd: nativeAd)

            return nil
        }) {[weak self] (_: AVOError) in
            guard let sSelf = self else {return}
            sSelf.reportError("AvocarrotSDK ad load error!")
        }
	}

	func reportError(_ msg: String) {
		delegate.nativeCustomEvent(self, didFailToLoadAdWithError: MPNativeAdNSErrorForInvalidAdServerResponse(msg))
	}

    /**
     Removes escape characters from the `urlString` and return an URL object.
     
     - Parameter urlString: string of the url
     - Returns: URL object
     */
    func escapeUrl(urlString: String) -> URL? {
        guard let escapedUrl = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }

        return  URL(string: escapedUrl)
    }

    /**
     Transforms string urls to URL objects.
     
     - Parameter urlStrings: array of string urls
     - Returns: URL array object

    */
    func getImageUrls(urlStrings: [String?]) -> [URL] {
        var images = [URL]()
        for item in urlStrings {
            if let urlString = item {

                guard !urlString.isEmpty else {
                    continue
                }

                var url = URL(string: urlString)

                if url == nil {
                    url = escapeUrl(urlString: urlString)
                }

                guard let safeUrl = url  else {
                    continue
                }

                images.append(safeUrl)
            }

        }
        return images
    }

    func preloadAdImages(forNativeAd nativeAd: AVONativeAssets) {
        let mopubAd = MPNativeAd(adAdapter: avocarrotCustomAdapter)
        let images = getImageUrls(urlStrings: [nativeAd.iconURL, nativeAd.imageURL])

        precacheImages(withURLs: images, completionBlock: { [weak self] (error: [Any]?) in
            guard let sSelf = self else {return}
            if error != nil {
                sSelf.delegate.nativeCustomEvent(sSelf, didFailToLoadAdWithError: MPNativeAdNSErrorForImageDownloadFailure())
            } else {
                sSelf.delegate.nativeCustomEvent(sSelf, didLoad: mopubAd)
            }
        })
    }

}
