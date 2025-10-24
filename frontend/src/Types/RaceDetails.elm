module Types.RaceDetails exposing (RaceDetails, Weather, raceDetailsDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import Types.Date exposing (Date, dateDecoder)



-- Types


type alias Weather =
    { airTemp : Maybe Float
    , trackTemp : Maybe Float
    , humidity : Maybe Float
    }


type alias RaceDetails =
    { round : Int
    , raceName : String
    , circuitName : String
    , country : String
    , date : Maybe Date
    , totalLaps : Int
    , raceDuration : Maybe String
    , circuitLength : Maybe Float
    , numCorners : Maybe Int
    , raceDistance : Maybe Float
    , weather : Maybe Weather
    }



-- Decoders


weatherDecoder : Decoder Weather
weatherDecoder =
    Decode.succeed Weather
        |> required "airTemp" (Decode.nullable Decode.float)
        |> required "trackTemp" (Decode.nullable Decode.float)
        |> required "humidity" (Decode.nullable Decode.float)


raceDetailsDecoder : Decoder RaceDetails
raceDetailsDecoder =
    Decode.succeed RaceDetails
        |> required "round" Decode.int
        |> required "raceName" Decode.string
        |> required "circuitName" Decode.string
        |> required "country" Decode.string
        |> required "date" dateDecoder
        |> required "totalLaps" Decode.int
        |> optional "raceDuration" (Decode.nullable raceDurationDecoder) Nothing
        |> optional "circuitLength" (Decode.nullable Decode.float) Nothing
        |> optional "numCorners" (Decode.nullable Decode.int) Nothing
        |> optional "raceDistance" (Decode.nullable Decode.float) Nothing
        |> optional "weather" (Decode.nullable weatherDecoder) Nothing


raceDurationDecoder : Decoder String
raceDurationDecoder =
    Decode.string
        |> Decode.map formatRaceDuration



-- Format "0 days 01:20:43.273000" to "1h 20m 43s"


formatRaceDuration : String -> String
formatRaceDuration duration =
    let
        -- Extract time part after "days "
        timePart =
            String.split " " duration
                |> List.drop 2
                |> String.join " "
                |> String.split ":"

        -- Parse hours, minutes, seconds
        ( hours, minutes, seconds ) =
            case timePart of
                [ h, m, s ] ->
                    ( String.toInt h |> Maybe.withDefault 0
                    , String.toInt m |> Maybe.withDefault 0
                    , String.toFloat s |> Maybe.withDefault 0 |> floor
                    )

                _ ->
                    ( 0, 0, 0 )
    in
    if hours > 0 then
        String.fromInt hours ++ "h " ++ String.fromInt minutes ++ "m " ++ String.fromInt seconds ++ "s"

    else if minutes > 0 then
        String.fromInt minutes ++ "m " ++ String.fromInt seconds ++ "s"

    else
        String.fromInt seconds ++ "s"
