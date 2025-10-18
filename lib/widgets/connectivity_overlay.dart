import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityOverlay extends StatefulWidget {
  final Widget child;
  const ConnectivityOverlay({super.key, required this.child});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late final StreamSubscription<InternetStatus> _internetStatusSub;
  bool _isOffline = false;
  bool _isInitialized = false;
  int _consecutiveFailures = 0;
  Timer? _graceTimer;

  @override
  void initState() {
    super.initState();
    _initialProbe();
    _setupListeners();
  }

  void _setupListeners() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      if (!_isInitialized) return;

      final hasNetwork = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );

      if (!hasNetwork) {
        _setOffline(true);
        return;
      }

      // Small grace window after a network change to avoid false negatives
      _graceTimer?.cancel();
      _graceTimer = Timer(const Duration(milliseconds: 900), _verifyInternet);
    });

    _internetStatusSub = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      if (!_isInitialized) return;

      if (status == InternetStatus.disconnected) {
        // Re-verify with longer timeout to avoid flagging slow networks
        _verifyInternet(timeout: const Duration(seconds: 6));
      } else {
        _resetFailures();
        _setOffline(false);
      }
    });
  }

  Future<void> _initialProbe() async {
    // First-run check with a short delay to let radios settle
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final hasConnection = await _checkConnection();

    if (mounted) {
      setState(() {
        _isOffline = !hasConnection;
        _isInitialized = true;
      });
    }
  }

  Future<bool> _checkConnection() async {
    try {
      // First check if we have network connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasNetwork = connectivityResults.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );

      if (!hasNetwork) return false;

      // Then verify actual internet access (robust custom check)
      final hasInternet = await _hasInternetRobust(
        overallTimeout: const Duration(seconds: 5),
      );

      return hasInternet;
    } catch (_) {
      return false;
    }
  }

  Future<void> _verifyInternet({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    // Perform up to three checks to avoid marking slow networks as offline
    bool first = false;
    bool second = false;
    bool third = false;

    try {
      first = await _hasInternetRobust(overallTimeout: timeout);

      if (!first) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        second = await _hasInternetRobust(overallTimeout: timeout);
      }

      if (!first && !second) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        third = await _hasInternetRobust(overallTimeout: timeout);
      }
    } catch (_) {
      first = false;
      second = false;
      third = false;
    }

    if (first || second || third) {
      _resetFailures();
      _setOffline(false);
    } else {
      _registerFailure();
    }
  }

  Future<bool> _hasInternetRobust({
    Duration perRequestTimeout = const Duration(seconds: 3),
    Duration overallTimeout = const Duration(seconds: 7),
  }) async {
    final List<Uri> endpoints = <Uri>[
      Uri.parse('https://www.google.com/generate_204'),
      Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
      Uri.parse('https://www.cloudflare.com'),
      Uri.parse('https://microsoft.com'),
      Uri.parse('https://apple.com'),
    ];

    Future<bool> _tryHead(Uri url) async {
      try {
        final HttpClient client = HttpClient()
          ..connectionTimeout = perRequestTimeout;
        final HttpClientRequest req = await client
            .openUrl('HEAD', url)
            .timeout(
              perRequestTimeout,
              onTimeout: () => throw const SocketException('timeout'),
            );
        req.followRedirects = false;
        final HttpClientResponse res = await req.close().timeout(
          perRequestTimeout,
          onTimeout: () => throw const SocketException('timeout'),
        );
        client.close(force: true);
        // 204 (no content) or any 2xx/3xx generally indicates internet
        return (res.statusCode >= 200 && res.statusCode < 400);
      } catch (_) {
        return false;
      }
    }

    try {
      final List<Future<bool>> attempts = endpoints.map(_tryHead).toList();
      // Consider online if any endpoint succeeds within overall timeout
      final bool result = await Future.any<bool>([
        Future.wait(attempts).then((values) => values.any((v) => v)),
        Future<bool>.delayed(overallTimeout, () => false),
      ]);
      return result;
    } catch (_) {
      return false;
    }
  }

  void _registerFailure() {
    _consecutiveFailures++;
    // Only mark offline after three consecutive failures to filter slow links
    if (_consecutiveFailures >= 3) {
      _setOffline(true);
    }
  }

  void _resetFailures() {
    _consecutiveFailures = 0;
  }

  void _setOffline(bool value) {
    if (!mounted || _isOffline == value || !_isInitialized) return;
    setState(() => _isOffline = value);
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    _connectivitySub.cancel();
    _internetStatusSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_isInitialized && _isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _OfflineBanner(
              onRetry: () =>
                  _verifyInternet(timeout: const Duration(seconds: 5)),
            ),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const Text(
                'No Internet Connection',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
