//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateGameSessionRequest {
  /// Returns a new [CreateGameSessionRequest] instance.
  CreateGameSessionRequest({
    required this.gameType,
  });

  /// Type of game to create
  CreateGameSessionRequestGameTypeEnum gameType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateGameSessionRequest &&
    other.gameType == gameType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (gameType.hashCode);

  @override
  String toString() => 'CreateGameSessionRequest[gameType=$gameType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'game_type'] = this.gameType;
    return json;
  }

  /// Returns a new [CreateGameSessionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateGameSessionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateGameSessionRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateGameSessionRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateGameSessionRequest(
        gameType: CreateGameSessionRequestGameTypeEnum.fromJson(json[r'game_type'])!,
      );
    }
    return null;
  }

  static List<CreateGameSessionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateGameSessionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateGameSessionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateGameSessionRequest> mapFromJson(dynamic json) {
    final map = <String, CreateGameSessionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateGameSessionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateGameSessionRequest-objects as value to a dart map
  static Map<String, List<CreateGameSessionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateGameSessionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateGameSessionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'game_type',
  };
}

/// Type of game to create
class CreateGameSessionRequestGameTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const CreateGameSessionRequestGameTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const tictactoe = CreateGameSessionRequestGameTypeEnum._(r'tictactoe');

  /// List of all possible values in this [enum][CreateGameSessionRequestGameTypeEnum].
  static const values = <CreateGameSessionRequestGameTypeEnum>[
    tictactoe,
  ];

  static CreateGameSessionRequestGameTypeEnum? fromJson(dynamic value) => CreateGameSessionRequestGameTypeEnumTypeTransformer().decode(value);

  static List<CreateGameSessionRequestGameTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateGameSessionRequestGameTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateGameSessionRequestGameTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CreateGameSessionRequestGameTypeEnum] to String,
/// and [decode] dynamic data back to [CreateGameSessionRequestGameTypeEnum].
class CreateGameSessionRequestGameTypeEnumTypeTransformer {
  factory CreateGameSessionRequestGameTypeEnumTypeTransformer() => _instance ??= const CreateGameSessionRequestGameTypeEnumTypeTransformer._();

  const CreateGameSessionRequestGameTypeEnumTypeTransformer._();

  String encode(CreateGameSessionRequestGameTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CreateGameSessionRequestGameTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CreateGameSessionRequestGameTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'tictactoe': return CreateGameSessionRequestGameTypeEnum.tictactoe;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CreateGameSessionRequestGameTypeEnumTypeTransformer] instance.
  static CreateGameSessionRequestGameTypeEnumTypeTransformer? _instance;
}


