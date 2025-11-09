module Utils exposing (..)

import Http


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error - is the API running?"

        Http.BadStatus status ->
            case status of
                503 ->
                    "Live F1 schedule data is temporarily unavailable. Please try again shortly."

                502 ->
                    "Upstream F1 data services are currently unreachable."

                404 ->
                    "Next race data is not available right now. Please check back soon."

                _ ->
                    "Unexpected response from the API (status " ++ String.fromInt status ++ ")."

        Http.BadBody message ->
            "Bad body: " ++ message
