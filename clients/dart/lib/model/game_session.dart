//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GameSession {
  /// Returns a new [GameSession] instance.
  GameSession({
    required this.id,
    required this.status,
    required this.minPlayers,
    required this.maxPlayers,
    required this.currentPlayerIndex,
    required this.gameType,
    this.players = const [],
    this.board = const [],
    this.winner,
  });

  /// Unique identifier for the game session
  int id;

  /// Current state of the game session
  GameSessionStatusEnum status;

  /// Minimum number of players required
  int minPlayers;

  /// Maximum number of players allowed
  int maxPlayers;

  /// Index of the current player in the players array
  int currentPlayerIndex;

  /// Type of game being played
  GameSessionGameTypeEnum gameType;

  /// List of players in the game
  List<Player> players;

  /// Current state of the game board
  List<String> board;

  /// ID of the winning player, null if game is not finished
  int? winner;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GameSession &&
    other.id == id &&
    other.status == status &&
    other.minPlayers == minPlayers &&
    other.maxPlayers == maxPlayers &&
    other.currentPlayerIndex == currentPlayerIndex &&
    other.gameType == gameType &&
    _deepEquality.equals(other.players, players) &&
    _deepEquality.equals(other.board, board) &&
    other.winner == winner;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (minPlayers.hashCode) +
    (maxPlayers.hashCode) +
    (currentPlayerIndex.hashCode) +
    (gameType.hashCode) +
    (players.hashCode) +
    (board.hashCode) +
    (winner == null ? 0 : winner!.hashCode);

  @override
  String toString() => 'GameSession[id=$id, status=$status, minPlayers=$minPlayers, maxPlayers=$maxPlayers, currentPlayerIndex=$currentPlayerIndex, gameType=$gameType, players=$players, board=$board, winner=$winner]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
      json[r'min_players'] = this.minPlayers;
      json[r'max_players'] = this.maxPlayers;
      json[r'current_player_index'] = this.currentPlayerIndex;
      json[r'game_type'] = this.gameType;
      json[r'players'] = this.players;
      json[r'board'] = this.board;
    if (this.winner != null) {
      json[r'winner'] = this.winner;
    } else {
      json[r'winner'] = null;
    }
    return json;
  }

  /// Returns a new [GameSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GameSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GameSession[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GameSession[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GameSession(
        id: mapValueOfType<int>(json, r'id')!,
        status: GameSessionStatusEnum.fromJson(json[r'status'])!,
        minPlayers: mapValueOfType<int>(json, r'min_players')!,
        maxPlayers: mapValueOfType<int>(json, r'max_players')!,
        currentPlayerIndex: mapValueOfType<int>(json, r'current_player_index')!,
        gameType: GameSessionGameTypeEnum.fromJson(json[r'game_type'])!,
        players: Player.listFromJson(json[r'players']),
        board: json[r'board'] is Iterable
            ? (json[r'board'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        winner: mapValueOfType<int>(json, r'winner'),
      );
    }
    return null;
  }

  static List<GameSession> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GameSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GameSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GameSession> mapFromJson(dynamic json) {
    final map = <String, GameSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GameSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GameSession-objects as value to a dart map
  static Map<String, List<GameSession>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GameSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GameSession.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'min_players',
    'max_players',
    'current_player_index',
    'game_type',
    'players',
    'board',
  };
}

/// Current state of the game session
class GameSessionStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const GameSessionStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const waiting = GameSessionStatusEnum._(r'waiting');
  static const active = GameSessionStatusEnum._(r'active');
  static const finished = GameSessionStatusEnum._(r'finished');

  /// List of all possible values in this [enum][GameSessionStatusEnum].
  static const values = <GameSessionStatusEnum>[
    waiting,
    active,
    finished,
  ];

  static GameSessionStatusEnum? fromJson(dynamic value) => GameSessionStatusEnumTypeTransformer().decode(value);

  static List<GameSessionStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GameSessionStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GameSessionStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GameSessionStatusEnum] to String,
/// and [decode] dynamic data back to [GameSessionStatusEnum].
class GameSessionStatusEnumTypeTransformer {
  factory GameSessionStatusEnumTypeTransformer() => _instance ??= const GameSessionStatusEnumTypeTransformer._();

  const GameSessionStatusEnumTypeTransformer._();

  String encode(GameSessionStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GameSessionStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GameSessionStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'waiting': return GameSessionStatusEnum.waiting;
        case r'active': return GameSessionStatusEnum.active;
        case r'finished': return GameSessionStatusEnum.finished;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GameSessionStatusEnumTypeTransformer] instance.
  static GameSessionStatusEnumTypeTransformer? _instance;
}


/// Type of game being played
class GameSessionGameTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const GameSessionGameTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const tictactoe = GameSessionGameTypeEnum._(r'tictactoe');

  /// List of all possible values in this [enum][GameSessionGameTypeEnum].
  static const values = <GameSessionGameTypeEnum>[
    tictactoe,
  ];

  static GameSessionGameTypeEnum? fromJson(dynamic value) => GameSessionGameTypeEnumTypeTransformer().decode(value);

  static List<GameSessionGameTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GameSessionGameTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GameSessionGameTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GameSessionGameTypeEnum] to String,
/// and [decode] dynamic data back to [GameSessionGameTypeEnum].
class GameSessionGameTypeEnumTypeTransformer {
  factory GameSessionGameTypeEnumTypeTransformer() => _instance ??= const GameSessionGameTypeEnumTypeTransformer._();

  const GameSessionGameTypeEnumTypeTransformer._();

  String encode(GameSessionGameTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GameSessionGameTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GameSessionGameTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'tictactoe': return GameSessionGameTypeEnum.tictactoe;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GameSessionGameTypeEnumTypeTransformer] instance.
  static GameSessionGameTypeEnumTypeTransformer? _instance;
}


