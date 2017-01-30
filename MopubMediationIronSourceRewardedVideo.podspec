Pod::Spec.new do |s|
  s.name             = 'MopubMediationIronSourceRewardedVideo'
  s.version          = '1.0.0'
  s.summary          = 'ironSource Rewarded Video Mediation Adapter for Mopub.'
  s.description      = 'ironSource Rewarded Video Mediation Adapter for Mopub.'

  s.homepage         = 'https://github.com/mopub/mopub-ios-sdk'

  s.license          = { :type => 'New BSD', :file => 'LICENSE' }
  s.author           = { 'Max Kattner' => 'mail@maxkattner.de' }
  s.source           = { :git => 'https://github.com/mopub/mopub-ios-sdk.git' }

  s.ios.deployment_target = '8.0'

  s.source_files = 'AdNetworkSupport/ironSource/RewardedVideo/*.{h,m}'
end
