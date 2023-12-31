import 'dart:async';

import 'package:nyxx/nyxx.dart';

/// Rotates around several statuses that are displayed as the client's activity
/// on Discord.
class StatusRotate extends NyxxPlugin<NyxxGateway> {
  /// The time for which each status is shown.
  static const updateInterval = Duration(minutes: 3);

  /// The statuses that can be shown.
  final statuses = <String>[
    'Playing Super Dash!',
    'Trying to understand zones...',
    'Fluttering around :D',
    'Dashing forwards!',
    'Loving Dart!',
    'Looking for Mega-Dash 👀',
    'Launching isolates!',
  ];

  @override
  NyxxPluginState<NyxxGateway, StatusRotate> createState() =>
      _StatusRotateState(this);
}

class _StatusRotateState extends NyxxPluginState<NyxxGateway, StatusRotate> {
  _StatusRotateState(super.plugin);

  Timer? timer;
  int index = 0;

  void _updateStatus(NyxxGateway client) {
    final status = plugin.statuses[index++ % plugin.statuses.length];

    client.updatePresence(PresenceBuilder(
      status: CurrentUserStatus.online,
      isAfk: false,
      activities: [
        ActivityBuilder(name: status, type: ActivityType.custom, state: status)
      ],
    ));
  }

  @override
  Future<void> afterConnect(NyxxGateway client) async {
    await super.afterConnect(client);
    _updateStatus(client);
    timer = Timer.periodic(
      StatusRotate.updateInterval,
      (_) => _updateStatus(client),
    );
  }

  @override
  Future<void> beforeClose(NyxxGateway client) async {
    await super.beforeClose(client);
    timer?.cancel();
  }
}
