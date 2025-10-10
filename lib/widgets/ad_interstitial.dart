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
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
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
    if (_interstitialAd == null) {
      await load();
    }

    if (_interstitialAd == null) {
      onClosed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
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
