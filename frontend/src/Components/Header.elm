module Components.Header exposing (view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Route


view : Html msg
view =
    Html.nav
        [ css
            [ backgroundColor (hex "#000000")
            , borderBottom3 (px 1) solid (rgba 239 68 68 0.3)
            , padding2 (rem 1) (rem 1.5)
            , position fixed
            , top zero
            , left zero
            , right zero
            , zIndex (int 50)
            , property "backdrop-filter" "blur(12px)"
            , backgroundColor (rgba 0 0 0 0.8)
            ]
        ]
        [ Html.div
            [ css
                [ maxWidth (px 1400)
                , margin2 zero auto
                , displayFlex
                , alignItems center
                , justifyContent spaceBetween
                ]
            ]
            [ -- Logo section
              Html.a
                [ Route.href Route.RaceOverview
                , css
                    [ displayFlex
                    , alignItems center
                    , textDecoration none
                    , fontSize (rem 1.5)
                    , fontWeight bold
                    , property "background" "linear-gradient(to right, #ef4444, #f87171)"
                    , property "-webkit-background-clip" "text"
                    , property "background-clip" "text"
                    , property "-webkit-text-fill-color" "transparent"
                    , property "transition" "all 0.3s ease"
                    ]
                ]
                [ Html.text "F1 DASHBOARD" ]

            -- Navigation links
            , Html.div
                [ css
                    [ displayFlex
                    , property "gap" "2rem"
                    , fontSize (rem 0.875)
                    , fontWeight (int 600)
                    ]
                ]
                [ navLink "RACES" Route.RaceOverview
                ]
            ]
        ]


navLink : String -> Route.Route -> Html msg
navLink label route =
    Html.a
        [ Route.href route
        , css
            [ color (hex "#9ca3af")
            , textDecoration none
            , hover
                [ color (hex "#ef4444")
                ]
            , property "transition" "color 0.3s ease"
            ]
        ]
        [ Html.text label ]
