import 'dart:math';

class ConnectedDeviceEntity {
  final String id;
  final String name;
  bool isNearby;

  ConnectedDeviceEntity({
    this.id = '',
    this.name = '',
    this.isNearby = true,
  });
  factory ConnectedDeviceEntity.fromJson(Map<String, dynamic> json) =>
      ConnectedDeviceEntity(
        id: json['id'],
        name: json['name'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  String toString() =>
      'ConnectedDeviceEntity(id: $id, name: $name, isNearby: $isNearby)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConnectedDeviceEntity) return false;
    if (runtimeType != other.runtimeType) return false;
    if (id != other.id) return false;
    if (name != other.name) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(id, name);

  bool get isEmpty => id.isEmpty;
}

class SimplePodcastEntity {
  final String title;
  final String subtitle;
  final String artUrl;
  final String streamUrl;
  final int position;
  final int duration;

  SimplePodcastEntity({
    required this.title,
    required this.subtitle,
    required this.artUrl,
    required this.streamUrl,
    required this.position,
    required this.duration,
  });

  factory SimplePodcastEntity.fromJson(Map<String, dynamic> json) {
    return SimplePodcastEntity(
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        artUrl: json['artUrl'] ?? '',
        streamUrl: json['streamUrl'] ?? '',
        position: json['position'] ?? 0,
        duration: json['duration'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['subtitle'] = subtitle;
    data['artUrl'] = artUrl;
    data['streamUrl'] = streamUrl;
    data['position'] = position;
    data['duration'] = duration;

    return data;
  }

  SimplePodcastEntity copyWith({
    String? title,
    String? subtitle,
    String? artUrl,
    String? streamUrl,
    int? position,
    int? duration,
  }) {
    return SimplePodcastEntity(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        artUrl: artUrl ?? this.artUrl,
        streamUrl: streamUrl ?? this.streamUrl,
        position: position ?? this.position,
        duration: duration ?? this.duration);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SimplePodcastEntity) return false;
    if (other.title != title) return false;
    if (other.subtitle != subtitle) return false;
    if (other.artUrl != artUrl) return false;
    if (other.streamUrl != streamUrl) return false;
    if (other.position != position) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(title, subtitle, artUrl, streamUrl, position);
}

class CommandEntity {
  late final int cmdId;
  final ConnectedDeviceEntity sender;
  ConnectedDeviceEntity? target;
  int? channel;
  bool? play;
  SimplePodcastEntity? simplePodcastEntity;

  /// true는 response를 의미한다.
  bool commandFinished;

  CommandEntity(
      {int? existId,
      required this.sender,
      this.target,
      this.channel,
      this.play,
      this.commandFinished = false,
      this.simplePodcastEntity}) {
    if (existId == null) {
      cmdId = Random().nextInt(999) + 1000;
    } else {
      cmdId = existId;
    }
  }

  factory CommandEntity.fromJson(Map<String, dynamic> json) {
    if (json['messageType'] != 'command') {
      throw FormatException('JSON parsing error: Not a CommandEntity type.');
    }
    return CommandEntity(
      existId: json['cmdId'],
      sender: ConnectedDeviceEntity.fromJson(json['sender']),
      target: (json['target'] == null)
          ? null
          : ConnectedDeviceEntity.fromJson(json['target']),
      channel: json['channel'],
      play: json['play'],
      simplePodcastEntity: (json['simplePodcastEntity'] == null)
          ? null
          : SimplePodcastEntity.fromJson(json['simplePodcastEntity']),
      commandFinished: json['commandFinished'],
    );
  }

  CommandEntity copyWith({
    int? existId,
    ConnectedDeviceEntity? sender,
    ConnectedDeviceEntity? target,
    int? channel,
    bool? play,
    SimplePodcastEntity? simplePodcastEntity,
    bool? commandFinished,
  }) {
    return CommandEntity(
      existId: existId ?? cmdId,
      sender: sender ?? this.sender,
      target: target ?? this.target,
      channel: channel ?? this.channel,
      play: play ?? this.play,
      simplePodcastEntity: simplePodcastEntity ?? this.simplePodcastEntity,
      commandFinished: commandFinished ?? this.commandFinished,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cmdId': cmdId,
      'messageType': 'command',
      'sender': sender.toJson(),
      if (target != null) 'target': target!.toJson(),
      if (channel != null) 'channel': channel,
      if (play != null) 'play': play,
      'commandFinished': commandFinished,
      if (simplePodcastEntity != null)
        'simplePodcastEntity': simplePodcastEntity!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommandEntity) return false;
    if (runtimeType != other.runtimeType) return false;
    if (cmdId != other.cmdId) return false;
    if (sender != other.sender) return false;
    if (target != other.target) return false;
    if (channel != other.channel) return false;
    if (play != other.play) return false;
    if (simplePodcastEntity != other.simplePodcastEntity) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        cmdId,
        sender,
        target,
        channel,
        play,
        simplePodcastEntity,
      );
}

class DevicePlayerStateEntity {
  final ConnectedDeviceEntity ctrlDevice;
  bool playing;
  int channel;
  int processingState;
  DateTime? updateTime;
  Duration? duration;
  Duration updatePosition;
  Duration bufferedPosition;
  int? currentIndex;
  int? androidAudioSessionId;
  int? errorCode;
  String? errorMessage;

  DevicePlayerStateEntity({
    required this.ctrlDevice,
    required this.playing,
    required this.channel,
    required this.processingState,
    required this.updateTime,
    required this.duration,
    required this.updatePosition,
    required this.bufferedPosition,
    required this.currentIndex,
    required this.androidAudioSessionId,
    required this.errorCode,
    required this.errorMessage,
  });

  factory DevicePlayerStateEntity.fromJson(Map<String, dynamic> json) {
    if (json['messageType'] != 'state') {
      throw FormatException(
          'JSON parsing error: Not a DevicePlayerStateEntity type.');
    }
    Duration? parseDuration(dynamic value) =>
        value != null ? Duration(milliseconds: value as int) : null;
    DateTime? parseDateTime(dynamic value) =>
        value != null ? DateTime.parse(value as String) : null;
    return DevicePlayerStateEntity(
      ctrlDevice: ConnectedDeviceEntity.fromJson(json['ctrlDevice']),
      playing: json['playing'],
      channel: json['channel'],
      updateTime: parseDateTime(json['updateTime']),
      duration: parseDuration(json['duration']),
      updatePosition: parseDuration(json['updatePosition']) ?? Duration.zero,
      bufferedPosition:
          parseDuration(json['bufferedPosition']) ?? Duration.zero,
      processingState: json['processingState'],
      currentIndex: json['currentIndex'],
      androidAudioSessionId: json['androidAudioSessionId'],
      errorCode: json['errorCode'],
      errorMessage: json['errorMessage'],
    );
  }
  // factory DevicePlayerStateEntity.fromOther({
  //   required ConnectedDeviceEntity sender,
  //   ConnectedDeviceEntity? target,
  //   int? channel,
  //   String status = 'status',
  //   required PlayerState playerState,
  //   required PlaybackEvent playbackEvent,
  // }) {
  //   return DevicePlayerStateEntity(
  //     sender: sender,
  //     playing: playerState.playing,
  //     processingState: playerState.processingState,
  //     updateTime: playbackEvent.updateTime,
  //     duration: playbackEvent.duration,
  //     updatePosition: playbackEvent.updatePosition,
  //     bufferedPosition: playbackEvent.bufferedPosition,
  //     currentIndex: playbackEvent.currentIndex,
  //     androidAudioSessionId: playbackEvent.androidAudioSessionId,
  //     errorCode: playbackEvent.errorCode,
  //     errorMessage: playbackEvent.errorMessage,
  //   );
  // }

  Map<String, dynamic> toJson() {
    return {
      'messageType': 'state',
      'ctrlDevice': ctrlDevice.toJson(),
      'playing': playing,
      'channel': channel,
      'processingState': processingState,
      'updatePosition': updatePosition.inMilliseconds,
      'bufferedPosition': bufferedPosition.inMilliseconds,
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
      if (currentIndex != null) 'currentIndex': currentIndex,
      if (androidAudioSessionId != null)
        'androidAudioSessionId': androidAudioSessionId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  DevicePlayerStateEntity copyWith({
    ConnectedDeviceEntity? ctrlDevice,
    bool? playing,
    int? channel,
    int? processingState,
    DateTime? updateTime,
    Duration? duration,
    Duration? updatePosition,
    Duration? bufferedPosition,
    int? currentIndex,
    int? androidAudioSessionId,
    int? errorCode,
    String? errorMessage,
  }) {
    return DevicePlayerStateEntity(
      ctrlDevice: ctrlDevice ?? this.ctrlDevice,
      playing: playing ?? this.playing,
      channel: channel ?? this.channel,
      processingState: processingState ?? this.processingState,
      updateTime: updateTime ?? this.updateTime,
      duration: duration ?? this.duration,
      updatePosition: updatePosition ?? this.updatePosition,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      currentIndex: currentIndex ?? this.currentIndex,
      androidAudioSessionId:
          androidAudioSessionId ?? this.androidAudioSessionId,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DevicePlayerStateEntity) return false;
    if (runtimeType != other.runtimeType) return false;
    if (ctrlDevice != other.ctrlDevice) return false;
    if (playing != other.playing) return false;
    if (channel != other.channel) return false;
    if (processingState != other.processingState) return false;
    if (updateTime != other.updateTime) return false;
    if (duration != other.duration) return false;
    if (updatePosition != other.updatePosition) return false;
    if (bufferedPosition != other.bufferedPosition) return false;
    if (currentIndex != other.currentIndex) return false;
    if (androidAudioSessionId != other.androidAudioSessionId) return false;
    if (errorCode != other.errorCode) return false;
    if (errorMessage != other.errorMessage) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        ctrlDevice,
        playing,
        channel,
        processingState,
        updateTime,
        duration,
        updatePosition,
        bufferedPosition,
        currentIndex,
        androidAudioSessionId,
        errorCode,
        errorMessage,
      );
}
