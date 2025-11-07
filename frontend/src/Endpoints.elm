module Endpoints exposing (..)

import Config
import Http
import Types.DriverOrder as DriverOrder exposing (DriverOrder)
import Types.NextRace exposing (NextRace, nextRaceDecoder)
import Types.PositionChanges as PositionChanges exposing (PositionChanges)
import Types.Race exposing (Race, racesListDecoder)
import Types.RaceDetails as RaceDetails exposing (RaceDetails)
import Types.RaceHighlights as RaceHighlights exposing (RaceHighlights)


baseUrl : String
baseUrl =
    Config.apiBaseUrl


loadNextRace : (Result Http.Error NextRace -> msg) -> Cmd msg
loadNextRace toMsg =
    Http.get
        { url = baseUrl ++ "/next-race"
        , expect = Http.expectJson toMsg nextRaceDecoder
        }


loadRaces : Int -> (Result Http.Error (List Race) -> msg) -> Cmd msg
loadRaces year toMsg =
    Http.get
        { url = baseUrl ++ "/races/" ++ String.fromInt year
        , expect =
            Http.expectJson toMsg
                racesListDecoder
        }


getRaceDetails : Int -> Int -> (Result Http.Error RaceDetails -> msg) -> Cmd msg
getRaceDetails year round toMsg =
    Http.get
        { url = baseUrl ++ "/race/" ++ String.fromInt year ++ "/" ++ String.fromInt round
        , expect = Http.expectJson toMsg RaceDetails.raceDetailsDecoder
        }


getDriverOrder : Int -> Int -> (Result Http.Error DriverOrder -> msg) -> Cmd msg
getDriverOrder year round toMsg =
    Http.get
        { url = baseUrl ++ "/race/" ++ String.fromInt year ++ "/" ++ String.fromInt round ++ "/drivers"
        , expect = Http.expectJson toMsg DriverOrder.driverOrderDecoder
        }


getPositionChanges : Int -> Int -> (Result Http.Error PositionChanges -> msg) -> Cmd msg
getPositionChanges year round toMsg =
    Http.get
        { url = baseUrl ++ "/race/" ++ String.fromInt year ++ "/" ++ String.fromInt round ++ "/positions"
        , expect = Http.expectJson toMsg PositionChanges.positionChangesDecoder
        }


getRaceHighlights : Int -> Int -> (Result Http.Error RaceHighlights -> msg) -> Cmd msg
getRaceHighlights year round toMsg =
    Http.get
        { url = baseUrl ++ "/race/" ++ String.fromInt year ++ "/" ++ String.fromInt round ++ "/highlights"
        , expect = Http.expectJson toMsg RaceHighlights.raceHighlightsDecoder
        }
