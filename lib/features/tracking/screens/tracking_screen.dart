import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/core/services/connectivity_service.dart';
import 'package:royal_app/core/utils/weather_helper.dart';
import 'package:royal_app/features/dashboard/providers/moto_provider.dart';
import 'package:royal_app/features/tracking/providers/tracking_provider.dart';
import 'package:royal_app/features/tracking/widgets/map_controls.dart';
import 'package:royal_app/features/tracking/widgets/map_style.dart';
import 'package:royal_app/features/tracking/widgets/ride_stats_panel.dart';
import 'package:royal_app/features/tracking/widgets/speed_hud.dart';
import 'package:royal_app/features/tracking/widgets/tracking_banner.dart';
import 'package:royal_app/features/tracking/widgets/tracking_map.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  // ── Constants ──────────────────────────────────────────────────────────────
  static const _defaultCenter = LatLng(23.0225, 72.5714);
  static const _zoom = 15.5;

  // ── State ──────────────────────────────────────────────────────────────────
  final _mapController = MapController();
  MapStyle _mapStyle = MapStyle.dark;
  bool _followUser = true;
  late AppLifecycleListener _lifecycleListener;

  // ── Pulse animation for position marker ───────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    // Notify provider when app goes background/foreground
    _lifecycleListener = AppLifecycleListener(
      onHide: () =>
          ref.read(trackingNotifierProvider.notifier).onAppBackground(),
      onShow: () =>
          ref.read(trackingNotifierProvider.notifier).onAppForeground(),
      onPause: () =>
          ref.read(trackingNotifierProvider.notifier).onAppBackground(),
      onResume: () =>
          ref.read(trackingNotifierProvider.notifier).onAppForeground(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _mapController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Follow + bearing-lock ──────────────────────────────────────────────────
  void _onPositionUpdate(LatLng pos, double heading) {
    if (!_followUser) return;
    _mapController.moveAndRotate(pos, _zoom, -heading);
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingNotifierProvider);
    final stats = ref.watch(rideStatsNotifierProvider);
    final tempAsync = ref.watch(ahmedabadTempProvider);
    final onlineAsync = ref.watch(isOnlineProvider);

    // Follow + bearing-lock whenever position or heading changes
    ref.listen(
      trackingNotifierProvider.select((s) => (s.currentPosition, s.heading)),
      (prev, next) {
        final (pos, heading) = next;
        if (pos != null) _onPositionUpdate(pos, heading);
      },
    );

    final center = tracking.currentPosition ?? _defaultCenter;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _TrackingAppBar(
        tracking: tracking,
        onRecenter: () {
          HapticFeedback.selectionClick();
          setState(() => _followUser = true);
          ref.read(trackingNotifierProvider.notifier).fetchCurrentLocation();
        },
      ),
      body: Stack(
        children: [
          // ── 1. Map ────────────────────────────────────────────────────
          TrackingMap(
            mapController: _mapController,
            tracking: tracking,
            mapStyle: _mapStyle,
            pulseAnim: _pulseAnim,
            initialCenter: center,
            zoom: _zoom,
            onGesture: () => setState(() => _followUser = false),
          ),

          // ── 2. Offline + heat banners ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 0,
            right: 0,
            child: Column(
              children: [
                onlineAsync.when(
                  data: (online) => online
                      ? const SizedBox.shrink()
                      : const TrackingBanner(
                          color: Color(0xCC1A1A1A),
                          icon: AppIcons.offline,
                          iconColor: Colors.orangeAccent,
                          text: 'Offline — map tiles may be limited',
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
                tempAsync.when(
                  data: (temp) => isHeatWarning(temp)
                      ? TrackingBanner(
                          color: Colors.red.shade900.withValues(alpha: 0.92),
                          icon: AppIcons.warning,
                          iconColor: Colors.white,
                          text: 'tracking.heat_alert'.tr(
                            namedArgs: {'temp': temp.toStringAsFixed(1)},
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── 3. Speed HUD (top-left) ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 50,
            left: 16,
            child: SpeedHud(tracking: tracking),
          ),

          // ── 4. Map controls (top-right) ───────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            right: 12,
            child: Column(
              children: [
                MapIconButton(
                  icon: _followUser ? AppIcons.navigation : AppIcons.locate,
                  active: _followUser,
                  tooltip: _followUser ? 'Bearing locked' : 'Re-center',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _followUser = true);
                    if (tracking.currentPosition != null) {
                      _mapController.moveAndRotate(
                        tracking.currentPosition!,
                        _zoom,
                        -tracking.heading,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                MapStyleButton(
                  current: _mapStyle,
                  onChanged: (s) => setState(() => _mapStyle = s),
                ),
              ],
            ),
          ),

          // ── 5. Bottom stats panel ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RideStatsPanel(tracking: tracking, stats: stats),
          ),
        ],
      ),
    );
  }
}

// ── AppBar ─────────────────────────────────────────────────────────────────────

class _TrackingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TrackingAppBar({required this.tracking, required this.onRecenter});

  final TrackingState tracking;
  final VoidCallback onRecenter;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.75),
      elevation: 0,
      title: Row(
        children: [
          const FaIcon(AppIcons.motorcycle, color: Color(0xFFFF6B00), size: 16),
          const SizedBox(width: 10),
          Text(
            'tracking.title'.tr(),
            style: AppFonts.heading(size: 18, letterSpacing: 1.5),
          ),
        ],
      ),
      actions: [
        if (tracking.isLocating)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF6B00),
              ),
            ),
          )
        else
          IconButton(
            icon: const FaIcon(
              AppIcons.locate,
              color: Color(0xFFFF6B00),
              size: 16,
            ),
            onPressed: onRecenter,
          ),
      ],
    );
  }
}
