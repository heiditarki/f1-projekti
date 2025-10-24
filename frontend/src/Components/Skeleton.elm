module Components.Skeleton exposing (viewSkeletonLayout, viewSkeletonPositionChart, viewSkeletonRaceHeader, viewSkeletonRaceHighlights, viewSkeletonRaceInfo, viewSkeletonRaceResults, viewSkeletonWeather)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)


viewSkeletonLayout : Html msg
viewSkeletonLayout =
    Html.div []
        [ viewSkeletonRaceHeader
        , Html.div
            [ css
                [ displayFlex
                , property "gap" "1rem"
                , alignItems flexStart
                , marginBottom (rem 2)
                ]
            ]
            [ Html.div
                [ css
                    [ flex (int 1)
                    , minWidth (px 300)
                    ]
                ]
                [ viewSkeletonRaceHighlights ]
            , Html.div
                [ css
                    [ flex (int 1)
                    , minWidth (px 300)
                    , displayFlex
                    , flexDirection column
                    , property "gap" "1rem"
                    ]
                ]
                [ Html.div
                    [ css
                        [ flex (int 1)
                        , minWidth (px 250)
                        ]
                    ]
                    [ viewSkeletonRaceInfo ]
                , Html.div
                    [ css
                        [ flex (int 1)
                        , minWidth (px 250)
                        ]
                    ]
                    [ viewSkeletonWeather ]
                ]
            ]
        , viewSkeletonPositionChart
        ]


viewSkeletonRaceHeader : Html msg
viewSkeletonRaceHeader =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 2)
            , marginBottom (rem 2)
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , justifyContent spaceBetween
                , alignItems center
                ]
            ]
            [ Html.div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , property "gap" "0.5rem"
                    ]
                ]
                [ viewSkeletonText 200 24
                , viewSkeletonText 150 16
                ]
            , viewSkeletonText 100 20
            ]
        ]


viewSkeletonRaceHighlights : Html msg
viewSkeletonRaceHighlights =
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
        [ viewSkeletonText 120 20
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , property "gap" "0.5rem"
                , marginTop (rem 1)
                ]
            ]
            [ viewSkeletonHighlight
            , viewSkeletonHighlight
            , viewSkeletonHighlight
            , viewSkeletonHighlight
            ]
        ]


viewSkeletonRaceInfo : Html msg
viewSkeletonRaceInfo =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 1.5)
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , flexWrap wrap
                , property "gap" "1rem"
                ]
            ]
            [ viewSkeletonInfoItem
            , viewSkeletonInfoItem
            , viewSkeletonInfoItem
            , viewSkeletonInfoItem
            , viewSkeletonInfoItem
            , viewSkeletonInfoItem
            ]
        ]


viewSkeletonWeather : Html msg
viewSkeletonWeather =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 1.5)
            , height (pct 100)
            , displayFlex
            , flexDirection column
            ]
        ]
        [ viewSkeletonText 120 16
        , Html.div
            [ css
                [ displayFlex
                , flexWrap wrap
                , property "gap" "1rem"
                , flex (int 1)
                , alignItems center
                ]
            ]
            [ viewSkeletonWeatherItem
            , viewSkeletonWeatherItem
            , viewSkeletonWeatherItem
            ]
        ]


viewSkeletonPositionChart : Html msg
viewSkeletonPositionChart =
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
        [ viewSkeletonText 150 20
        , Html.div
            [ css
                [ marginTop (rem 1)
                , height (px 300)
                , backgroundColor (rgba 20 15 30 0.3)
                , borderRadius (px 8)
                ]
            ]
            []
        ]


viewSkeletonText : Float -> Float -> Html msg
viewSkeletonText w h =
    Html.div
        [ css
            [ backgroundColor (rgba 255 255 255 0.1)
            , borderRadius (px 4)
            , width (px w)
            , height (px h)
            , property "animation" "pulse 1.5s ease-in-out infinite"
            ]
        ]
        []


viewSkeletonHighlight : Html msg
viewSkeletonHighlight =
    Html.div
        [ css
            [ displayFlex
            , alignItems center
            , justifyContent spaceBetween
            , padding (rem 0.75)
            , backgroundColor (rgba 20 15 30 0.3)
            , borderRadius (px 8)
            , borderLeft3 (px 3) solid (rgba 255 255 255 0.2)
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , alignItems center
                , property "gap" "0.75rem"
                ]
            ]
            [ Html.div
                [ css
                    [ width (px 20)
                    , height (px 20)
                    , backgroundColor (rgba 255 255 255 0.1)
                    , borderRadius (px 4)
                    ]
                ]
                []
            , Html.div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , alignItems flexStart
                    , property "gap" "0.25rem"
                    ]
                ]
                [ viewSkeletonText 80 12
                , viewSkeletonText 120 16
                ]
            ]
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , alignItems flexEnd
                , property "gap" "0.25rem"
                ]
            ]
            [ viewSkeletonText 60 14
            , viewSkeletonText 40 12
            ]
        ]


viewSkeletonInfoItem : Html msg
viewSkeletonInfoItem =
    Html.div
        [ css
            [ flex (int 1)
            , minWidth (px 120)
            ]
        ]
        [ Html.div
            [ css
                [ marginBottom (rem 0.2)
                ]
            ]
            [ viewSkeletonText 60 12
            ]
        , viewSkeletonText 80 16
        ]


viewSkeletonWeatherItem : Html msg
viewSkeletonWeatherItem =
    Html.div
        [ css
            [ flex (int 1)
            , minWidth (px 100)
            , textAlign center
            ]
        ]
        [ Html.div
            [ css
                [ marginBottom (rem 0.5)
                ]
            ]
            [ viewSkeletonText 60 12
            ]
        , viewSkeletonText 40 16
        ]


viewSkeletonRaceResults : Html msg
viewSkeletonRaceResults =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 1.5)
            , position sticky
            , top (rem 2)
            ]
        ]
        [ viewSkeletonText 120 20
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , property "gap" "0.5rem"
                , marginTop (rem 1)
                ]
            ]
            [ viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            , viewSkeletonDriverItem
            ]
        ]


viewSkeletonDriverItem : Html msg
viewSkeletonDriverItem =
    Html.div
        [ css
            [ displayFlex
            , alignItems center
            , justifyContent spaceBetween
            , padding (rem 0.75)
            , backgroundColor (rgba 20 15 30 0.3)
            , borderRadius (px 8)
            , borderLeft3 (px 3) solid (rgba 255 255 255 0.2)
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , alignItems center
                , property "gap" "0.75rem"
                ]
            ]
            [ Html.div
                [ css
                    [ width (px 24)
                    , height (px 24)
                    , backgroundColor (rgba 255 255 255 0.1)
                    , borderRadius (px 4)
                    ]
                ]
                []
            , Html.div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , alignItems flexStart
                    , property "gap" "0.25rem"
                    ]
                ]
                [ viewSkeletonText 100 14
                , viewSkeletonText 80 12
                ]
            ]
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , alignItems flexEnd
                , property "gap" "0.25rem"
                ]
            ]
            [ viewSkeletonText 60 14
            , viewSkeletonText 40 12
            ]
        ]
