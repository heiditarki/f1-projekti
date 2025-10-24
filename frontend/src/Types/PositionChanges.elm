module Types.PositionChanges exposing (DriverPosition, PositionChanges, positionChangesDecoder)

import Json.Decode as Decode exposing (Decoder, int, list, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)


type alias DriverPosition =
    { driverNumber : Maybe Int
    , code : Maybe String
    , team : Maybe String
    , teamColor : Maybe String
    , positions : List (Maybe Int) -- Position at each lap
    , pitLaps : List Int
    , dnfLap : Maybe Int
    }


type alias PositionChanges =
    { year : Int
    , round : Int
    , raceName : String
    , totalLaps : Int
    , drivers : List DriverPosition
    }


driverPositionDecoder : Decoder DriverPosition
driverPositionDecoder =
    Decode.succeed DriverPosition
        |> optional "driverNumber" (nullable int) Nothing
        |> optional "code" (nullable string) Nothing
        |> optional "team" (nullable string) Nothing
        |> optional "teamColor" (nullable string) Nothing
        |> required "positions" (list (nullable int))
        |> required "pitLaps" (list int)
        |> optional "dnfLap" (nullable int) Nothing


positionChangesDecoder : Decoder PositionChanges
positionChangesDecoder =
    Decode.succeed PositionChanges
        |> required "year" int
        |> required "round" int
        |> required "raceName" string
        |> required "totalLaps" int
        |> required "drivers" (list driverPositionDecoder)
