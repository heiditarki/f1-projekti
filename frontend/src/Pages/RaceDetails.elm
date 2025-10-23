module Pages.RaceDetails exposing (Model, Msg, init, update, view)

import Components.Spinner as Spinner
import Css exposing (..)
import Endpoints
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events
import Http
import Route
import Types.Date exposing (toString)
import Types.RaceDetails exposing (RaceDetails, Weather)
import Types.RemoteData exposing (RemoteData(..))
import Utils



-- MODEL


type alias Model =
    { raceId : String
    , year : Int
    , round : Int
    , raceDetails : RemoteData String RaceDetails
    }


init : String -> ( Model, Cmd Msg )
init raceId =
    let
        ( year, round ) =
            case String.split "-" raceId of
                [ yearStr, roundStr ] ->
                    case ( String.toInt yearStr, String.toInt roundStr ) of
                        ( Just y, Just r ) ->
                            ( y, r )

                        _ ->
                            ( 2024, Maybe.withDefault 1 (String.toInt raceId) )

                _ ->
                    case String.toInt raceId of
                        Just r ->
                            ( 2024, r )

                        Nothing ->
                            ( 2024, 1 )
    in
    ( { raceId = raceId
      , year = year
      , round = round
      , raceDetails = Loading
      }
    , Endpoints.getRaceDetails year round GotRaceDetails
    )



-- MSG


type Msg
    = GotRaceDetails (Result Http.Error RaceDetails)
    | Retry



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotRaceDetails (Ok details) ->
            ( { model | raceDetails = Success details }
            , Cmd.none
            )

        GotRaceDetails (Err error) ->
            ( { model | raceDetails = Failure (Utils.httpErrorToString error) }
            , Cmd.none
            )

        Retry ->
            ( { model | raceDetails = Loading }
            , Endpoints.getRaceDetails model.year model.round GotRaceDetails
            )



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ viewBackButton
        , viewRaceContent model
        ]


viewBackButton : Html msg
viewBackButton =
    Html.div
        [ css [ marginBottom (rem 2) ]
        ]
        [ Html.a
            [ Route.href Route.RaceOverview
            , css
                [ display inlineBlock
                , color (hex "#94a3b8")
                , textDecoration none
                , fontSize (rem 0.95)
                , hover [ color (hex "#ef4444") ]
                , property "transition" "color 0.2s"
                ]
            ]
            [ Html.text "← Back to races" ]
        ]


viewRaceContent : Model -> Html Msg
viewRaceContent model =
    case model.raceDetails of
        NotAsked ->
            viewPlaceholder "Not requested yet"

        Loading ->
            Spinner.viewWithText "Loading race details"

        Success details ->
            viewRaceDetails details

        Failure error ->
            viewError error


viewError : String -> Html Msg
viewError error =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 239 68 68 0.5)
            , borderRadius (px 16)
            , padding (rem 3)
            , textAlign center
            ]
        ]
        [ Html.h2
            [ css
                [ color (hex "#ef4444")
                , fontSize (rem 1.5)
                , marginBottom (rem 1)
                ]
            ]
            [ Html.text "Error Loading Race" ]
        , Html.p
            [ css
                [ color (hex "#94a3b8")
                , marginBottom (rem 2)
                ]
            ]
            [ Html.text error ]
        , Html.button
            [ css
                [ backgroundColor (hex "#ef4444")
                , color (hex "#ffffff")
                , padding2 (rem 0.5) (rem 1.5)
                , borderRadius (px 8)
                , border zero
                , cursor pointer
                , fontSize (rem 1)
                , hover [ backgroundColor (hex "#dc2626") ]
                ]
            , Html.Styled.Events.onClick Retry
            ]
            [ Html.text "Retry" ]
        ]


viewRaceDetails : RaceDetails -> Html msg
viewRaceDetails details =
    Html.div []
        [ viewRaceHeader details
        , viewRaceInfo details
        , viewWeather details.weather
        ]


viewRaceHeader : RaceDetails -> Html msg
viewRaceHeader details =
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
        [ Html.h1
            [ css
                [ fontSize (rem 2.5)
                , fontWeight bold
                , marginBottom (rem 0.5)
                ]
            ]
            [ Html.text details.raceName ]
        , Html.p
            [ css
                [ color (hex "#94a3b8")
                , fontSize (rem 1.2)
                ]
            ]
            [ Html.text (details.circuitName ++ ", " ++ details.country) ]
        ]


viewRaceInfo : RaceDetails -> Html msg
viewRaceInfo details =
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
                , flexWrap wrap
                , property "gap" "1.5rem"
                ]
            ]
            [ viewInfoItem "Round" (String.fromInt details.round)
            , viewInfoItem "Date" (details.date |> Maybe.map toString |> Maybe.withDefault "N/A")
            , viewInfoItem "Total Laps" (String.fromInt details.totalLaps)
            , viewInfoItem "Race Duration" (Maybe.withDefault "N/A" details.raceDuration)
            ]
        ]


viewInfoItem : String -> String -> Html msg
viewInfoItem label value =
    Html.div
        [ css
            [ flex (int 1)
            , minWidth (px 150)
            ]
        ]
        [ Html.div
            [ css
                [ color (hex "#94a3b8")
                , fontSize (rem 0.85)
                , marginBottom (rem 0.3)
                ]
            ]
            [ Html.text label ]
        , Html.div
            [ css
                [ color (hex "#ffffff")
                , fontSize (rem 1.2)
                , fontWeight bold
                ]
            ]
            [ Html.text value ]
        ]


viewWeather : Maybe Weather -> Html msg
viewWeather maybeWeather =
    case maybeWeather of
        Nothing ->
            Html.text ""

        Just weather ->
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
                        [ fontSize (rem 1.3)
                        , fontWeight bold
                        , marginBottom (rem 1)
                        , color (hex "#60a5fa")
                        ]
                    ]
                    [ Html.text "Weather Conditions" ]
                , Html.div
                    [ css
                        [ displayFlex
                        , flexWrap wrap
                        , property "gap" "1.5rem"
                        ]
                    ]
                    [ viewWeatherItem "Air Temp" weather.airTemp "°C"
                    , viewWeatherItem "Track Temp" weather.trackTemp "°C"
                    , viewWeatherItem "Humidity" weather.humidity "%"
                    ]
                ]


viewWeatherItem : String -> Maybe Float -> String -> Html msg
viewWeatherItem label maybeValue unit =
    Html.div
        [ css
            [ flex (int 1)
            , minWidth (px 120)
            ]
        ]
        [ Html.div
            [ css
                [ color (hex "#94a3b8")
                , fontSize (rem 0.85)
                , marginBottom (rem 0.3)
                ]
            ]
            [ Html.text label ]
        , Html.div
            [ css
                [ color (hex "#ffffff")
                , fontSize (rem 1.2)
                , fontWeight bold
                ]
            ]
            [ Html.text
                (case maybeValue of
                    Just value ->
                        String.fromFloat value ++ unit

                    Nothing ->
                        "N/A"
                )
            ]
        ]


viewPlaceholder : String -> Html msg
viewPlaceholder message =
    Html.div
        [ css
            [ backgroundColor (hex "#1e293b")
            , borderRadius (px 12)
            , padding (rem 3)
            , textAlign center
            , border3 (px 2) solid (hex "#334155")
            ]
        ]
        [ Html.text message ]
