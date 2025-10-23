import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef InterstitialOnClosed = void Function();

class InterstitialAdManager {
  InterstitialAdManager({required this.adUnitId});

  final String adUnitId;
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoading || _interstitialAd != null) return;
    _isLoading = true;
    debugPrint('Loading interstitial ad with unit ID: $adUnitId');

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  Future<void> show({InterstitialOnClosed? onClosed}) async {
    debugPrint('Attempting to show interstitial ad');

    if (_interstitialAd == null) {
      debugPrint('Ad not loaded, attempting to load...');
      await load();
    }

    if (_interstitialAd == null) {
      debugPrint('Ad still not available after loading attempt');
      onClosed?.call();
      return;
    }

    debugPrint('Showing interstitial ad');
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        onClosed?.call();
        // Preload next
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        onClosed?.call();
        load();
      },
    );

    await _interstitialAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
