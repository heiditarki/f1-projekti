module Components.Footer exposing (view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)


view : Html msg
view =
    Html.footer
        [ Attr.class "site-footer"
        , css
            [ backgroundColor (hex "#000000")
            , borderTop3 (px 1) solid (hex "#1f1f1f")
            , padding2 (rem 2) (rem 3)
            , marginTop auto
            , width (pct 100)
            , boxSizing borderBox
            ]
        ]
        [ Html.div
            [ Attr.class "site-footer__inner"
            , css
                [ maxWidth (px 1400)
                , width (pct 100)
                , margin2 zero auto
                , displayFlex
                , justifyContent spaceBetween
                , alignItems center
                , flexWrap wrap
                , property "gap" "1rem"
                , color (rgba 255 255 255 0.65)
                , fontSize (rem 0.85)
                ]
            ]
            [ Html.div
                [ Attr.class "site-footer__intro"
                , css
                    [ displayFlex
                    , alignItems center
                    , property "gap" "0.5rem"
                    ]
                ]
                [ Html.span [] [ Html.text "Built by" ]
                , Html.a
                    [ Attr.href "https://github.com/heiditarki/f1-projekti"
                    , Attr.target "_blank"
                    , css
                        [ color (hex "#ef4444")
                        , textDecoration none
                        , fontWeight (int 600)
                        , property "transition" "color 0.2s ease"
                        , hover [ color (hex "#ffffff") ]
                        ]
                    ]
                    [ Html.text "Heidi Tarkiainen" ]
                ]
            , Html.div
                [ Attr.class "site-footer__links"
                , css
                    [ displayFlex
                    , alignItems center
                    , property "gap" "0.6rem"
                    ]
                ]
                [ viewFooterLink "API Docs" "https://docs.fastf1.dev/"
                , viewFooterLink "Repository" "https://github.com/heiditarki/f1-projekti"
                ]
            , Html.div
                [ css
                    [ color (rgba 255 255 255 0.4)
                    , fontSize (rem 0.75)
                    ]
                ]
                [ Html.text "© "
                , Html.text (String.fromInt 2025)
                , Html.text " F1 Dashboard"
                ]
            ]
        ]


viewFooterLink : String -> String -> Html msg
viewFooterLink label url =
    Html.a
        [ Attr.href url
        , Attr.target "_blank"
        , css
            [ color (rgba 255 255 255 0.7)
            , textDecoration none
            , fontSize (rem 0.8)
            , property "transition" "color 0.2s ease"
            , hover [ color (hex "#ef4444") ]
            ]
        ]
        [ Html.text label ]
