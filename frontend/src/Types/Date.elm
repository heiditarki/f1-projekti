module Types.Date exposing (Date, dateDecoder, fromString, toString)

import Json.Decode as Decode exposing (Decoder)


type Date
    = Date Int Month Int


type Month
    = January
    | February
    | March
    | April
    | May
    | June
    | July
    | August
    | September
    | October
    | November
    | December


fromString : String -> Maybe Date
fromString dateString =
    let
        parts =
            String.split "-" dateString
    in
    case parts of
        [ yearStr, monthStr, dayStr ] ->
            Maybe.map3 Date
                (String.toInt yearStr)
                (String.toInt monthStr |> Maybe.andThen intToMonth)
                (String.toInt dayStr)

        _ ->
            Nothing


intToMonth : Int -> Maybe Month
intToMonth n =
    case n of
        1 ->
            Just January

        2 ->
            Just February

        3 ->
            Just March

        4 ->
            Just April

        5 ->
            Just May

        6 ->
            Just June

        7 ->
            Just July

        8 ->
            Just August

        9 ->
            Just September

        10 ->
            Just October

        11 ->
            Just November

        12 ->
            Just December

        _ ->
            Nothing


monthToString : Month -> String
monthToString month =
    case month of
        January ->
            "January"

        February ->
            "February"

        March ->
            "March"

        April ->
            "April"

        May ->
            "May"

        June ->
            "June"

        July ->
            "July"

        August ->
            "August"

        September ->
            "September"

        October ->
            "October"

        November ->
            "November"

        December ->
            "December"


toString : Date -> String
toString (Date year month day) =
    monthToString month ++ " " ++ String.fromInt day ++ ", " ++ String.fromInt year


dateDecoder : Decoder (Maybe Date)
dateDecoder =
    Decode.oneOf
        [ Decode.null Nothing
        , Decode.string
            |> Decode.andThen
                (\str ->
                    if str == "NaT" || str == "" then
                        Decode.succeed Nothing

                    else
                        case fromString str of
                            Just date ->
                                Decode.succeed (Just date)

                            Nothing ->
                                Decode.succeed Nothing
                )
        ]
