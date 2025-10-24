module Endpoints exposing (..)

import Http
import Types.DriverOrder as DriverOrder exposing (DriverOrder)
import Types.PositionChanges as PositionChanges exposing (PositionChanges)
import Types.Race as Race exposing (Race)
import Types.RaceDetails as RaceDetails exposing (RaceDetails)


baseUrl : String
baseUrl =
    "http://127.0.0.1:8000"


loadRaces : (Result Http.Error (List Race) -> msg) -> Cmd msg
loadRaces toMsg =
    Http.get
        { url = baseUrl ++ "/races/2024"
        , expect =
            Http.expectJson toMsg
                Race.racesListDecoder
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
