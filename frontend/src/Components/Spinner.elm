module Components.Spinner exposing (view, viewWithText)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)



-- Basic spinner without text


view : Html msg
view =
    Html.div
        [ css
            [ width (px 40)
            , height (px 40)
            , border3 (px 4) solid (hex "#334155")
            , borderTopColor (hex "#ef4444")
            , borderRadius (pct 50)
            , property "animation" "spin 1s linear infinite"
            ]
        ]
        []



-- Spinner with text below


viewWithText : String -> Html msg
viewWithText text =
    Html.div
        [ css
            [ displayFlex
            , flexDirection column
            , alignItems center
            , justifyContent center
            , property "gap" "1rem"
            , paddingTop (rem 4)
            ]
        ]
        [ view
        , Html.div
            [ css
                [ color (hex "#ffffff")
                , fontSize (rem 1.5)
                , fontWeight bold
                ]
            ]
            [ Html.text text
            , Html.span [ css [ property "animation" "dots 1.5s infinite" ] ] [ Html.text "." ]
            , Html.span [ css [ property "animation" "dots 1.5s 0.5s infinite" ] ] [ Html.text "." ]
            , Html.span [ css [ property "animation" "dots 1.5s 1s infinite" ] ] [ Html.text "." ]
            ]
        ]
