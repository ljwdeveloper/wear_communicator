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

class CommandEntity {
  late final int cmdId;
  final ConnectedDeviceEntity sender;
  ConnectedDeviceEntity? target;
  int? channel;
  bool? play;

  /// true는 response를 의미한다.
  bool commandFinished;

  CommandEntity({
    int? existId,
    required this.sender,
    this.target,
    this.channel,
    this.play,
    this.commandFinished = false,
  }) {
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
      target: json['target'] == null
          ? null
          : ConnectedDeviceEntity.fromJson(json['target']),
      channel: json['channel'],
      play: json['play'],
      commandFinished: json['commandFinished'],
    );
  }

  CommandEntity copyWith({
    int? existId,
    ConnectedDeviceEntity? sender,
    ConnectedDeviceEntity? target,
    int? channel,
    bool? play,
    bool? getLastCtrl,
    bool? commandFinished,
  }) {
    return CommandEntity(
      existId: existId ?? cmdId,
      sender: sender ?? this.sender,
      target: target ?? this.target,
      channel: channel ?? this.channel,
      play: play ?? this.play,
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
    return true;
  }

  @override
  int get hashCode => Object.hash(
        cmdId,
        sender,
        target,
        channel,
        play,
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
