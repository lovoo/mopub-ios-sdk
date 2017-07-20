//
//  AvocarrotMoPubCustomAdapter.swift
//  AvocarrotSDKAdapters
//
//  Created by  Glispa GmbH on 15/06/16.
//  Copyright © 2016  Glispa GmbH. All rights reserved.
//

import Foundation
import MoPub
import AvocarrotNativeAssets

@objc(AvocarrotMoPubCustomAdapter)
open class AvocarrotMoPubCustomAdapter: NSObject, MPNativeAdAdapter {
	/**
	 * Provides a dictionary of all publicly accessible assets (such as title and text) for the
	 * native ad.
	 *
	 * When possible, you should place values in the returned dictionary such that they correspond to
	 * the pre-defined keys in the MPNativeAdConstants header file.
	 */
	weak open var delegate: MPNativeAdAdapterDelegate?
	open var properties = [AnyHashable: Any]()

	fileprivate let ad: AVONativeAssets

	public init(ad: AVONativeAssets) {

		self.ad = ad

		properties[kAdTitleKey] = ad.title
		properties[kAdTextKey] = ad.text
		properties[kAdIconImageKey] = ad.iconURL
		properties[kAdMainImageKey] = ad.imageURL
		properties[kAdCTATextKey] = ad.callToActionTitle
		properties[kAdStarRatingKey] = "\(ad.starRating)"
        properties[kVASTVideoKey] = ad.vastString
	}

	/**
	 * The default click-through URL for the ad.
	 *
	 * This may safely be set to nil if your network doesn't expose this value (for example, it may only
	 * provide a method to handle a click, lacking another for retrieving the URL itself).
	 */
	open let defaultActionURL: URL? = nil

	/**
	 * Determines whether MPNativeAd should track clicks
	 *
	 * If not implemented, this will be assumed to return NO, and MPNativeAd will track clicks.
	 * If this returns YES, then MPNativeAd will defer to the MPNativeAdAdapterDelegate callbacks to
	 * track clicks.
	 */
	open func enableThirdPartyClickTracking() -> Bool {
		return true
	}

	/** @name Responding to an Ad Being Attached to a View */

	/**
	 * This method will be called when your ad's content is about to be loaded into a view.
	 *
	 * @param view A view that will contain the ad content.
	 *
	 * You should implement this method if the underlying third-party ad object needs to be informed
	 * of this event.
	 */

	open func willAttach(to view: UIView!) {
        self.ad.registerView(forInteraction: view, forClickableSubviews: nil)

	}
	/*
	 Informs Mopub for the clicked registered
	 */
	open func registerClickToMopub() {
		guard let nativeAdDidClick = delegate?.nativeAdDidClick else { print("Delegate does not implement click tracking callback. Clicks likely not being tracked."); return }
		nativeAdDidClick(self)
	}

	/*
	 Informs Mopub for the impression registered
	 */
	open func registerImpressionToMopub() {
		guard let nativeAdWillLogImpression = delegate?.nativeAdWillLogImpression else { print("Delegate does not implement click tracking callback. Clicks likely not being tracked."); return }
		nativeAdWillLogImpression(self)
	}

	/*
	 Informs Mopub that the web view is closed
	 */
	open func registerFinishHandlingClickToMopub() {
		delegate?.nativeAdDidDismissModal(for: self)
	}

}
