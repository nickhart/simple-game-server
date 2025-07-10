# simple_game_client.model.GameSession

## Load the model package
```dart
import 'package:simple_game_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** | Unique identifier for the game session | 
**status** | **String** | Current state of the game session | 
**minPlayers** | **int** | Minimum number of players required | 
**maxPlayers** | **int** | Maximum number of players allowed | 
**currentPlayerIndex** | **int** | Index of the current player in the players array | 
**gameType** | **String** | Type of game being played | 
**players** | [**List<Player>**](Player.md) | List of players in the game | [default to const []]
**board** | **List<String>** | Current state of the game board | [default to const []]
**winner** | **int** | ID of the winning player, null if game is not finished | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


