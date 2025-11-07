module Components.Countdown exposing (Props, view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import String
import Types.NextRace exposing (Countdown, CountdownStatus(..))


type alias Props msg =
    { countdown : Maybe Countdown
    , raceName : Maybe String
    , officialName : Maybe String
    , circuit : Maybe String
    , country : Maybe String
    , actionAttributes : List (Html.Attribute msg)
    , actionLabel : String
    }


view : Props msg -> Html msg
view props =
    Html.section
        [ css
            [ backgroundColor (hex "#0a0a0a")
            , border3 (px 1) solid (hex "#1f1f1f")
            , borderRadius (px 16)
            , padding (rem 3)
            , color (hex "#ffffff")
            , displayFlex
            , flexDirection column
            , property "gap" "2rem"
            , width (pct 100)
            , maxWidth (px 600)
            ]
        ]
        [ viewHeader props
        , viewCountdown props.countdown
        , viewActionMaybe props
        ]


viewHeader : Props msg -> Html msg
viewHeader props =
    Html.div
        [ css
            [ displayFlex
            , flexDirection column
            , property "gap" "0.5rem"
            ]
        ]
        [ Html.span
            [ css
                [ textTransform uppercase
                , letterSpacing (px 2)
                , fontSize (rem 0.7)
                , color (hex "#666666")
                , fontWeight (int 600)
                ]
            ]
            [ Html.text "NEXT RACE" ]
        , Html.h1
            [ css
                [ fontSize (rem 2.2)
                , fontWeight bold
                , margin zero
                , lineHeight (num 1.2)
                ]
            ]
            [ Html.text (raceTitle props) ]
        , Html.span
            [ css
                [ color (hex "#888888")
                , fontSize (rem 1)
                ]
            ]
            [ Html.text (raceLocation props) ]
        ]


raceTitle : Props msg -> String
raceTitle props =
    case ( props.raceName, props.officialName ) of
        ( Just race, _ ) ->
            let
                trimmed =
                    String.trim race
            in
            if trimmed /= "" then
                trimmed

            else
                Maybe.withDefault "To be announced" props.officialName

        ( Nothing, Just official ) ->
            official

        _ ->
            "To be announced"


raceLocation : Props msg -> String
raceLocation props =
    case ( props.circuit, props.country ) of
        ( Just circuit, Just country ) ->
            circuit ++ " • " ++ country

        ( Just circuit, Nothing ) ->
            circuit

        ( Nothing, Just country ) ->
            country

        _ ->
            "Awaiting confirmation"


viewCountdown : Maybe Countdown -> Html msg
viewCountdown maybeCountdown =
    case maybeCountdown of
        Nothing ->
            placeholder "Countdown unavailable"

        Just countdown ->
            case countdown.status of
                Started ->
                    placeholder "Race is underway"

                Upcoming ->
                    Html.div
                        [ css
                            [ property "display" "grid"
                            , property "grid-template-columns" "repeat(4, 1fr)"
                            , property "gap" "1rem"
                            ]
                        ]
                        [ viewSegment "Days" countdown.days
                        , viewSegment "Hours" countdown.hours
                        , viewSegment "Mins" countdown.minutes
                        , viewSegment "Secs" countdown.seconds
                        ]


viewSegment : String -> Int -> Html msg
viewSegment label value =
    Html.div
        [ css
            [ borderRadius (px 12)
            , backgroundColor (hex "#151515")
            , border3 (px 1) solid (hex "#2a2a2a")
            , padding2 (rem 1.5) (rem 0.5)
            , textAlign center
            , displayFlex
            , flexDirection column
            , property "gap" "0.5rem"
            ]
        ]
        [ Html.span
            [ css
                [ fontSize (rem 2.5)
                , fontWeight bold
                , color (hex "#ef4444")
                , property "font-variant-numeric" "tabular-nums"
                ]
            ]
            [ Html.text (valueString value) ]
        , Html.span
            [ css
                [ fontSize (rem 0.7)
                , textTransform uppercase
                , letterSpacing (px 1)
                , color (hex "#666666")
                , fontWeight (int 500)
                ]
            ]
            [ Html.text label ]
        ]


valueString : Int -> String
valueString value =
    value
        |> max 0
        |> String.fromInt
        |> String.padLeft 2 '0'


viewActionMaybe : Props msg -> Html msg
viewActionMaybe props =
    case ( props.actionAttributes, props.actionLabel ) of
        ( [], "" ) ->
            Html.text ""

        _ ->
            Html.a
                (props.actionAttributes
                    ++ [ css
                            [ backgroundColor (hex "#ef4444")
                            , color (hex "#ffffff")
                            , fontSize (rem 1)
                            , fontWeight (int 500)
                            , borderRadius (px 8)
                            , padding2 (rem 0.9) (rem 2)
                            , textDecoration none
                            , property "display" "inline-flex"
                            , property "justify-content" "center"
                            , property "align-items" "center"
                            , border zero
                            , cursor pointer
                            , property "transition" "all 0.2s ease"
                            , hover
                                [ backgroundColor (hex "#dc2626")
                                , transform (translateY (px -1))
                                ]
                            ]
                       ]
                )
                [ Html.text props.actionLabel ]


placeholder : String -> Html msg
placeholder message =
    Html.div
        [ css
            [ backgroundColor (hex "#151515")
            , border3 (px 1) solid (hex "#2a2a2a")
            , borderRadius (px 12)
            , padding2 (rem 1.5) (rem 1)
            , textAlign center
            , color (hex "#666666")
            , fontSize (rem 0.9)
            ]
        ]
        [ Html.text message ]
