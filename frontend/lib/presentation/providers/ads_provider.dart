import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob configuration constants
class AdConfig {
  static const String appId = 'ca-app-pub-1394062189372273~8291105865';
  static const String bannerAdUnitId = 'ca-app-pub-1394062189372273/5477240266';
  static const String rewardedAdUnitId = 'ca-app-pub-1394062189372273/9806387579';
}

/// Service to manage AdMob ads
class AdService {
  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadRewardedAd();
  }

  /// Create a banner ad with listener
  BannerAd createBannerAd({
    required void Function() onLoaded,
    required void Function(LoadAdError) onFailed,
  }) {
    return BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          developer.log('Banner ad loaded');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          developer.log('Banner ad failed to load: $error');
          ad.dispose();
          onFailed(error);
        },
      ),
    );
  }

  /// Load a rewarded ad
  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          developer.log('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
          developer.log('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  /// Show rewarded ad, returns true if ad was shown
  Future<bool> showRewardedAd({
    required Function onRewarded,
    Function? onAdDismissed,
  }) async {
    if (_rewardedAd == null) {
      _loadRewardedAd();
      return false;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;

    return ad.show(
      onUserEarnedReward: (ad, reward) {
        developer.log('User earned reward: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    ).then((_) {
      _loadRewardedAd();
      onAdDismissed?.call();
      return true;
    }).catchError((error) {
      developer.log('Failed to show rewarded ad: $error');
      _loadRewardedAd();
      onAdDismissed?.call();
      return false;
    });
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

/// Riverpod provider for AdService
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(() => service.dispose());
  return service;
});