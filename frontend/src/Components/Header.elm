module Components.Header exposing (view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Route


view : Html msg
view =
    Html.nav
        [ Attr.class "site-nav"
        , css
            [ backgroundColor (hex "#000000")
            , padding2 (rem 1.2) (rem 3)
            , position fixed
            , top zero
            , left zero
            , right zero
            , zIndex (int 1000)
            ]
        ]
        [ Html.div
            [ Attr.class "site-nav__inner"
            , css
                [ maxWidth (px 1400)
                , margin2 zero auto
                , displayFlex
                , alignItems center
                , justifyContent spaceBetween
                ]
            ]
            [ viewLogo
            , viewNavLink
            ]
        ]


viewLogo : Html msg
viewLogo =
    Html.a
        [ Route.href Route.Home
        , Attr.class "site-nav__logo"
        , css
            [ displayFlex
            , alignItems baseline
            , textDecoration none
            , property "gap" "0.4rem"
            ]
        ]
        [ Html.span
            [ css
                [ color (hex "#ef4444")
                , fontSize (rem 1.3)
                , fontWeight bold
                , letterSpacing (px 1)
                ]
            ]
            [ Html.text "F1" ]
        , Html.span
            [ css
                [ color (hex "#ffffff")
                , fontSize (rem 1.3)
                , fontWeight (int 300)
                , letterSpacing (px 0.5)
                ]
            ]
            [ Html.text "DASHBOARD" ]
        ]


viewNavLink : Html msg
viewNavLink =
    Html.a
        [ Route.href (Route.RaceOverview 2025)
        , Attr.class "site-nav__link"
        , css
            [ color (hex "#ffffff")
            , textDecoration none
            , fontSize (rem 0.95)
            , fontWeight (int 400)
            , letterSpacing (px 0.5)
            , hover
                [ color (hex "#ef4444")
                ]
            , property "transition" "color 0.2s ease"
            ]
        ]
        [ Html.text "Races" ]
