module Components.RaceHighlights exposing (view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Types.RaceHighlights exposing (DriverHighlight, HighlightType(..), RaceHighlights)


view : RaceHighlights -> Html msg
view highlights =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 2)
            ]
        ]
        [ Html.h3
            [ css
                [ fontSize (rem 1.2)
                , fontWeight bold
                , marginBottom (rem 1)
                , color (hex "#ffffff")
                , textAlign left
                ]
            ]
            [ Html.text "Race Highlights" ]
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , property "gap" "0.5rem"
                ]
            ]
            [ viewHighlight Winner "Winner" highlights.winner
            , case highlights.fastestLap of
                Just fastestLap ->
                    viewHighlight FastestLap "Fastest Lap" fastestLap

                Nothing ->
                    Html.text ""
            , case highlights.fastestPitStop of
                Just fastestPit ->
                    viewHighlight FastestPitStop "Fastest Pit Stop" fastestPit

                Nothing ->
                    Html.text ""
            , case highlights.fastestSpeed of
                Just fastestSpeed ->
                    viewHighlight FastestSpeed "Fastest Speed" fastestSpeed

                Nothing ->
                    Html.text ""
            ]
        ]


viewHighlight : HighlightType -> String -> DriverHighlight -> Html msg
viewHighlight highlightType title driver =
    let
        teamColor =
            driver.teamColor
                |> Maybe.withDefault "ef4444"
                |> (\c -> "#" ++ c)

        icon =
            case highlightType of
                Winner ->
                    "🏆"

                FastestLap ->
                    "⚡"

                FastestPitStop ->
                    "🔧"

                FastestSpeed ->
                    "🚀"

        timeValue =
            case highlightType of
                FastestSpeed ->
                    driver.speed
                        |> Maybe.map (\speed -> String.fromFloat speed ++ " km/h")
                        |> Maybe.withDefault "N/A"

                _ ->
                    driver.time
                        |> Maybe.withDefault "N/A"

        lapInfo =
            case driver.lapNumber of
                Just lapNum ->
                    " (L" ++ String.fromInt lapNum ++ ")"

                Nothing ->
                    ""
    in
    Html.div
        [ css
            [ displayFlex
            , alignItems center
            , justifyContent spaceBetween
            , padding (rem 0.75)
            , backgroundColor (rgba 20 15 30 0.3)
            , borderRadius (px 8)
            , borderLeft3 (px 3) solid (hex teamColor)
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , alignItems center
                , property "gap" "0.75rem"
                ]
            ]
            [ Html.span
                [ css
                    [ fontSize (rem 1.2)
                    ]
                ]
                [ Html.text icon ]
            , Html.div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , alignItems flexStart
                    ]
                ]
                [ Html.div
                    [ css
                        [ fontSize (rem 0.8)
                        , fontWeight bold
                        , color (rgba 255 255 255 0.8)
                        ]
                    ]
                    [ Html.text title ]
                , Html.div
                    [ css
                        [ fontSize (rem 1)
                        , fontWeight bold
                        , color (hex teamColor)
                        ]
                    ]
                    [ Html.text (driver.driverName |> Maybe.withDefault "Unknown") ]
                ]
            ]
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , alignItems flexEnd
                ]
            ]
            [ Html.div
                [ css
                    [ fontSize (rem 0.9)
                    , fontWeight bold
                    , color (hex "#ffffff")
                    ]
                ]
                [ Html.text (timeValue ++ lapInfo) ]
            , case driver.points of
                Just points ->
                    Html.div
                        [ css
                            [ fontSize (rem 0.8)
                            , color (hex "#fbbf24")
                            ]
                        ]
                        [ Html.text (String.fromFloat points ++ " pts") ]

                Nothing ->
                    Html.text ""
            ]
        ]
