module Types.NextRace exposing
    ( Countdown
    , CountdownStatus(..)
    , NextRace
    , Sessions
    , decrement
    , nextRaceDecoder
    , normalize
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import String



-- TYPES


type alias NextRace =
    { year : Int
    , round : Maybe Int
    , raceName : Maybe String
    , officialName : Maybe String
    , circuit : Maybe String
    , country : Maybe String
    , dateUtc : Maybe String
    , sessions : Sessions
    , countdown : Maybe Countdown
    }


type alias Sessions =
    { fp1 : Maybe String
    , fp2 : Maybe String
    , fp3 : Maybe String
    , qualifying : Maybe String
    , race : Maybe String
    }


type alias Countdown =
    { status : CountdownStatus
    , totalSeconds : Int
    , days : Int
    , hours : Int
    , minutes : Int
    , seconds : Int
    }


type CountdownStatus
    = Upcoming
    | Started



-- DECODERS


nextRaceDecoder : Decoder NextRace
nextRaceDecoder =
    Decode.succeed NextRace
        |> required "year" Decode.int
        |> optional "round" (Decode.nullable Decode.int) Nothing
        |> optional "raceName" maybeStringDecoder Nothing
        |> optional "officialName" maybeStringDecoder Nothing
        |> optional "circuit" maybeStringDecoder Nothing
        |> optional "country" maybeStringDecoder Nothing
        |> optional "dateUtc" maybeStringDecoder Nothing
        |> optional "sessions" sessionsDecoder defaultSessions
        |> optional "countdown" (Decode.nullable countdownDecoder) Nothing


sessionsDecoder : Decoder Sessions
sessionsDecoder =
    Decode.succeed Sessions
        |> optional "fp1" maybeStringDecoder Nothing
        |> optional "fp2" maybeStringDecoder Nothing
        |> optional "fp3" maybeStringDecoder Nothing
        |> optional "qualifying" maybeStringDecoder Nothing
        |> optional "race" maybeStringDecoder Nothing


countdownDecoder : Decoder Countdown
countdownDecoder =
    Decode.map normalize
        (Decode.succeed Countdown
            |> required "status" countdownStatusDecoder
            |> required "totalSeconds" Decode.int
            |> required "days" Decode.int
            |> required "hours" Decode.int
            |> required "minutes" Decode.int
            |> required "seconds" Decode.int
        )


countdownStatusDecoder : Decoder CountdownStatus
countdownStatusDecoder =
    Decode.string
        |> Decode.andThen
            (\value ->
                case String.toLower value of
                    "upcoming" ->
                        Decode.succeed Upcoming

                    "started" ->
                        Decode.succeed Started

                    _ ->
                        Decode.fail "Unknown countdown status"
            )


maybeStringDecoder : Decoder (Maybe String)
maybeStringDecoder =
    Decode.oneOf
        [ Decode.null Nothing
        , Decode.string
            |> Decode.map
                (\str ->
                    if String.trim str == "" then
                        Nothing

                    else
                        Just str
                )
        ]


defaultSessions : Sessions
defaultSessions =
    Sessions Nothing Nothing Nothing Nothing Nothing



-- HELPERS


normalize : Countdown -> Countdown
normalize countdown =
    let
        clampedSeconds =
            if countdown.totalSeconds < 0 then
                0

            else
                countdown.totalSeconds

        secondsInDay =
            24 * 60 * 60

        days =
            clampedSeconds // secondsInDay

        remainderAfterDays =
            clampedSeconds - (days * secondsInDay)

        hours =
            remainderAfterDays // 3600

        remainderAfterHours =
            remainderAfterDays - (hours * 3600)

        minutes =
            remainderAfterHours // 60

        seconds =
            remainderAfterHours - (minutes * 60)

        status =
            if clampedSeconds <= 0 then
                Started

            else
                countdown.status
    in
    { status = status
    , totalSeconds = clampedSeconds
    , days = days
    , hours = hours
    , minutes = minutes
    , seconds = seconds
    }


decrement : Countdown -> Countdown
decrement countdown =
    { countdown | totalSeconds = countdown.totalSeconds - 1 }
        |> normalize
