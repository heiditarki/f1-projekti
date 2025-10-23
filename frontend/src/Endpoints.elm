module Endpoints exposing (..)

import Http
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
