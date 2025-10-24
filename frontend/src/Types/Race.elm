module Types.Race exposing (Race, racesListDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Types.Date exposing (Date, dateDecoder)



-- TYPE


type alias Race =
    { round : Int
    , race : String
    , date : Maybe Date
    }



-- DECODERS


raceDecoder : Decode.Decoder Race
raceDecoder =
    Decode.succeed Race
        |> required "round" Decode.int
        |> required "race" Decode.string
        |> required "date" dateDecoder


racesListDecoder : Decode.Decoder (List Race)
racesListDecoder =
    Decode.field "races" (Decode.list raceDecoder)
