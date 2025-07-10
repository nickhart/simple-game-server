//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MakeMoveRequest {
  /// Returns a new [MakeMoveRequest] instance.
  MakeMoveRequest({
    required this.playerId,
    required this.position,
  });

  /// ID of the player making the move
  int playerId;

  /// Position on the board (0-8)
  ///
  /// Minimum value: 0
  /// Maximum value: 8
  int position;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MakeMoveRequest &&
    other.playerId == playerId &&
    other.position == position;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (playerId.hashCode) +
    (position.hashCode);

  @override
  String toString() => 'MakeMoveRequest[playerId=$playerId, position=$position]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'player_id'] = this.playerId;
      json[r'position'] = this.position;
    return json;
  }

  /// Returns a new [MakeMoveRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MakeMoveRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MakeMoveRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MakeMoveRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MakeMoveRequest(
        playerId: mapValueOfType<int>(json, r'player_id')!,
        position: mapValueOfType<int>(json, r'position')!,
      );
    }
    return null;
  }

  static List<MakeMoveRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MakeMoveRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MakeMoveRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MakeMoveRequest> mapFromJson(dynamic json) {
    final map = <String, MakeMoveRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MakeMoveRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MakeMoveRequest-objects as value to a dart map
  static Map<String, List<MakeMoveRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MakeMoveRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MakeMoveRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'player_id',
    'position',
  };
}

