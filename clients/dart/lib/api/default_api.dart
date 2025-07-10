//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DefaultApi {
  DefaultApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new game session
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateGameSessionRequest] createGameSessionRequest (required):
  Future<Response> createGameSessionWithHttpInfo(CreateGameSessionRequest createGameSessionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/game_sessions';

    // ignore: prefer_final_locals
    Object? postBody = createGameSessionRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a new game session
  ///
  /// Parameters:
  ///
  /// * [CreateGameSessionRequest] createGameSessionRequest (required):
  Future<CreateGameSession200Response?> createGameSession(CreateGameSessionRequest createGameSessionRequest,) async {
    final response = await createGameSessionWithHttpInfo(createGameSessionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CreateGameSession200Response',) as CreateGameSession200Response;
    
    }
    return null;
  }

  /// Join an existing game session
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///   ID of the game session to join
  ///
  /// * [JoinGameSessionRequest] joinGameSessionRequest (required):
  Future<Response> joinGameSessionWithHttpInfo(int id, JoinGameSessionRequest joinGameSessionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/game_sessions/{id}/join'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = joinGameSessionRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Join an existing game session
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///   ID of the game session to join
  ///
  /// * [JoinGameSessionRequest] joinGameSessionRequest (required):
  Future<CreateGameSession200Response?> joinGameSession(int id, JoinGameSessionRequest joinGameSessionRequest,) async {
    final response = await joinGameSessionWithHttpInfo(id, joinGameSessionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CreateGameSession200Response',) as CreateGameSession200Response;
    
    }
    return null;
  }

  /// List all game sessions
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listGameSessionsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/game_sessions';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List all game sessions
  Future<ListGameSessions200Response?> listGameSessions() async {
    final response = await listGameSessionsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListGameSessions200Response',) as ListGameSessions200Response;
    
    }
    return null;
  }

  /// Make a move in the game
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///   ID of the game session
  ///
  /// * [MakeMoveRequest] makeMoveRequest (required):
  Future<Response> makeMoveWithHttpInfo(int id, MakeMoveRequest makeMoveRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/game_sessions/{id}/move'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = makeMoveRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Make a move in the game
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///   ID of the game session
  ///
  /// * [MakeMoveRequest] makeMoveRequest (required):
  Future<CreateGameSession200Response?> makeMove(int id, MakeMoveRequest makeMoveRequest,) async {
    final response = await makeMoveWithHttpInfo(id, makeMoveRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CreateGameSession200Response',) as CreateGameSession200Response;
    
    }
    return null;
  }
}
