import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner320x50 extends StatefulWidget {
  const AdBanner320x50({super.key});

  @override
  State<AdBanner320x50> createState() => _AdBanner320x50State();
}

class _AdBanner320x50State extends State<AdBanner320x50> {
  BannerAd? _bannerAd;
  AdWidget? _adWidget;
  final ValueNotifier<bool> _isLoadedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      size: const AdSize(width: 320, height: 50),
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-9698718721404755/4167494263' // Production banner ID
          : 'ca-app-pub-9698718721404755/4167494263', // Production banner ID
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Create a single AdWidget for this instance.
          if (_adWidget == null && _bannerAd != null) {
            _adWidget = AdWidget(ad: _bannerAd!);
          }
          _isLoadedNotifier.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _adWidget = null;
          _isLoadedNotifier.value = false;
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadedNotifier,
      builder: (context, isLoaded, _) {
        if (!isLoaded || _adWidget == null) {
          // Show placeholder when ad is not loaded
          return Container(
            width: 320,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'Google Ads',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        return SizedBox(width: 320, height: 50, child: _adWidget);
      },
    );
  }
}
