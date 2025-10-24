module Types.RaceHighlights exposing (DriverHighlight, HighlightType(..), RaceHighlights, raceHighlightsDecoder)

import Json.Decode as Decode exposing (Decoder, field, float, int, map7, map8, maybe, string)


type alias RaceHighlights =
    { year : Int
    , round : Int
    , raceName : String
    , winner : DriverHighlight
    , fastestLap : Maybe DriverHighlight
    , fastestPitStop : Maybe DriverHighlight
    , fastestSpeed : Maybe DriverHighlight
    }


type alias DriverHighlight =
    { driverCode : Maybe String
    , driverName : Maybe String
    , team : Maybe String
    , teamColor : Maybe String
    , lapNumber : Maybe Int
    , time : Maybe String
    , speed : Maybe Float
    , points : Maybe Float
    }


type HighlightType
    = Winner
    | FastestLap
    | FastestPitStop
    | FastestSpeed


winnerDecoder : Decoder DriverHighlight
winnerDecoder =
    map8 DriverHighlight
        (field "driverCode" (maybe string))
        (field "driverName" (maybe string))
        (field "team" (maybe string))
        (field "teamColor" (maybe string))
        (Decode.succeed Nothing)
        -- No lap number for winner
        (field "raceTime" (maybe string))
        (Decode.succeed Nothing)
        -- No speed for winner
        (field "points" (maybe float))


fastestLapDecoder : Decoder DriverHighlight
fastestLapDecoder =
    map8 DriverHighlight
        (field "driverCode" (maybe string))
        (field "driverName" (maybe string))
        (field "team" (maybe string))
        (field "teamColor" (maybe string))
        (field "lapNumber" (maybe int))
        (field "lapTime" (maybe string))
        (Decode.succeed Nothing)
        -- No speed for fastest lap
        (Decode.succeed Nothing)



-- No points for fastest lap


fastestPitDecoder : Decoder DriverHighlight
fastestPitDecoder =
    map8 DriverHighlight
        (field "driverCode" (maybe string))
        (field "driverName" (maybe string))
        (field "team" (maybe string))
        (field "teamColor" (maybe string))
        (field "lapNumber" (maybe int))
        (field "pitDuration" (maybe string))
        (Decode.succeed Nothing)
        -- No speed for fastest pit
        (Decode.succeed Nothing)



-- No points for fastest pit


fastestSpeedDecoder : Decoder DriverHighlight
fastestSpeedDecoder =
    map8 DriverHighlight
        (field "driverCode" (maybe string))
        (field "driverName" (maybe string))
        (field "team" (maybe string))
        (field "teamColor" (maybe string))
        (field "lapNumber" (maybe int))
        (Decode.succeed Nothing)
        -- No time for fastest speed
        (field "speed" (maybe float))
        (Decode.succeed Nothing)



-- No points for fastest speed


raceHighlightsDecoder : Decoder RaceHighlights
raceHighlightsDecoder =
    map7 RaceHighlights
        (field "year" int)
        (field "round" int)
        (field "raceName" string)
        (field "winner" winnerDecoder)
        (field "fastestLap" (maybe fastestLapDecoder))
        (field "fastestPitStop" (maybe fastestPitDecoder))
        (field "fastestSpeed" (maybe fastestSpeedDecoder))
