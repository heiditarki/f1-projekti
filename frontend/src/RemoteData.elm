module RemoteData exposing (RemoteData(..))


type RemoteData error data
    = Loading
    | Success data
    | Failure error
