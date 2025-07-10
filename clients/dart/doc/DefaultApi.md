# simple_game_client.api.DefaultApi

## Load the API package
```dart
import 'package:simple_game_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createGameSession**](DefaultApi.md#creategamesession) | **POST** /game_sessions | Create a new game session
[**joinGameSession**](DefaultApi.md#joingamesession) | **POST** /game_sessions/{id}/join | Join an existing game session
[**listGameSessions**](DefaultApi.md#listgamesessions) | **GET** /game_sessions | List all game sessions
[**makeMove**](DefaultApi.md#makemove) | **POST** /game_sessions/{id}/move | Make a move in the game


# **createGameSession**
> CreateGameSession200Response createGameSession(createGameSessionRequest)

Create a new game session

### Example
```dart
import 'package:simple_game_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DefaultApi();
final createGameSessionRequest = CreateGameSessionRequest(); // CreateGameSessionRequest | 

try {
    final result = api_instance.createGameSession(createGameSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createGameSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGameSessionRequest** | [**CreateGameSessionRequest**](CreateGameSessionRequest.md)|  | 

### Return type

[**CreateGameSession200Response**](CreateGameSession200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **joinGameSession**
> CreateGameSession200Response joinGameSession(id, joinGameSessionRequest)

Join an existing game session

### Example
```dart
import 'package:simple_game_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DefaultApi();
final id = 56; // int | ID of the game session to join
final joinGameSessionRequest = JoinGameSessionRequest(); // JoinGameSessionRequest | 

try {
    final result = api_instance.joinGameSession(id, joinGameSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->joinGameSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the game session to join | 
 **joinGameSessionRequest** | [**JoinGameSessionRequest**](JoinGameSessionRequest.md)|  | 

### Return type

[**CreateGameSession200Response**](CreateGameSession200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listGameSessions**
> ListGameSessions200Response listGameSessions()

List all game sessions

### Example
```dart
import 'package:simple_game_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DefaultApi();

try {
    final result = api_instance.listGameSessions();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listGameSessions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ListGameSessions200Response**](ListGameSessions200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **makeMove**
> CreateGameSession200Response makeMove(id, makeMoveRequest)

Make a move in the game

### Example
```dart
import 'package:simple_game_client/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DefaultApi();
final id = 56; // int | ID of the game session
final makeMoveRequest = MakeMoveRequest(); // MakeMoveRequest | 

try {
    final result = api_instance.makeMove(id, makeMoveRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->makeMove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the game session | 
 **makeMoveRequest** | [**MakeMoveRequest**](MakeMoveRequest.md)|  | 

### Return type

[**CreateGameSession200Response**](CreateGameSession200Response.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

