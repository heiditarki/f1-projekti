module Types.RemoteData exposing (RemoteData(..))


type RemoteData error data
    = NotAsked
    | Loading
    | Success data
    | Failure error
