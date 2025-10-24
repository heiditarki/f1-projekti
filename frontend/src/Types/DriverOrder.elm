module Types.DriverOrder exposing (Driver, DriverOrder, driverDecoder, driverOrderDecoder)

import Json.Decode as Decode exposing (Decoder, float, int, list, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)


type alias Driver =
    { position : Maybe Int
    , number : Maybe Int
    , code : Maybe String
    , firstName : Maybe String
    , lastName : Maybe String
    , team : Maybe String
    , teamColor : Maybe String
    , gridPosition : Maybe Int
    , status : Maybe String
    , points : Float
    , time : Maybe String
    }


type alias DriverOrder =
    { year : Int
    , round : Int
    , raceName : String
    , drivers : List Driver
    }


driverDecoder : Decoder Driver
driverDecoder =
    Decode.succeed Driver
        |> optional "position" (nullable int) Nothing
        |> optional "number" (nullable int) Nothing
        |> optional "code" (nullable string) Nothing
        |> optional "firstName" (nullable string) Nothing
        |> optional "lastName" (nullable string) Nothing
        |> optional "team" (nullable string) Nothing
        |> optional "teamColor" (nullable string) Nothing
        |> optional "gridPosition" (nullable int) Nothing
        |> optional "status" (nullable string) Nothing
        |> optional "points" float 0.0
        |> optional "time" (nullable string) Nothing


driverOrderDecoder : Decoder DriverOrder
driverOrderDecoder =
    Decode.succeed DriverOrder
        |> required "year" int
        |> required "round" int
        |> required "raceName" string
        |> required "drivers" (list driverDecoder)
