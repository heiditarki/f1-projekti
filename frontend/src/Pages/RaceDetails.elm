module Pages.RaceDetails exposing (Model, Msg, init, update, view)

import Components.PositionChart as PositionChart
import Components.RaceHighlights as RaceHighlights
import Components.Skeleton as Skeleton
import Components.Spinner as Spinner
import Css exposing (..)
import Endpoints
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Events
import Http
import RemoteData exposing (RemoteData(..))
import Route
import Types.Date exposing (toString)
import Types.DriverOrder exposing (Driver, DriverOrder)
import Types.PositionChanges exposing (PositionChanges)
import Types.RaceDetails exposing (RaceDetails, Weather)
import Types.RaceHighlights exposing (RaceHighlights)
import Utils



-- MODEL


type alias Model =
    { raceId : String
    , year : Int
    , round : Int
    , raceDetails : RemoteData String RaceDetails
    , driverOrder : RemoteData String DriverOrder
    , positionChanges : RemoteData String PositionChanges
    , raceHighlights : RemoteData String RaceHighlights
    , chartModel : Maybe PositionChart.Model
    }


init : Int -> String -> ( Model, Cmd Msg )
init year raceId =
    let
        round =
            case String.toInt raceId of
                Just r ->
                    r

                Nothing ->
                    1
    in
    ( { raceId = raceId
      , year = year
      , round = round
      , raceDetails = Loading
      , driverOrder = Loading
      , positionChanges = Loading
      , raceHighlights = Loading
      , chartModel = Nothing
      }
    , Cmd.batch
        [ Endpoints.getRaceDetails year round GotRaceDetails
        , Endpoints.getDriverOrder year round GotDriverOrder
        , Endpoints.getPositionChanges year round GotPositionChanges
        , Endpoints.getRaceHighlights year round GotRaceHighlights
        ]
    )



-- MSG


type Msg
    = GotRaceDetails (Result Http.Error RaceDetails)
    | GotDriverOrder (Result Http.Error DriverOrder)
    | GotPositionChanges (Result Http.Error PositionChanges)
    | GotRaceHighlights (Result Http.Error RaceHighlights)
    | ChartMsg PositionChart.Msg
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

        GotDriverOrder (Ok drivers) ->
            ( { model | driverOrder = Success drivers }
            , Cmd.none
            )

        GotDriverOrder (Err error) ->
            ( { model | driverOrder = Failure (Utils.httpErrorToString error) }
            , Cmd.none
            )

        GotPositionChanges (Ok changes) ->
            ( { model
                | positionChanges = Success changes
                , chartModel = Just (PositionChart.init changes)
              }
            , Cmd.none
            )

        GotPositionChanges (Err error) ->
            ( { model | positionChanges = Failure (Utils.httpErrorToString error) }
            , Cmd.none
            )

        GotRaceHighlights (Ok highlights) ->
            ( { model | raceHighlights = Success highlights }
            , Cmd.none
            )

        GotRaceHighlights (Err error) ->
            ( { model | raceHighlights = Failure (Utils.httpErrorToString error) }
            , Cmd.none
            )

        ChartMsg chartMsg ->
            case model.chartModel of
                Just chartModel ->
                    ( { model | chartModel = Just (PositionChart.update chartMsg chartModel) }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        Retry ->
            ( { model
                | raceDetails = Loading
                , driverOrder = Loading
                , positionChanges = Loading
                , raceHighlights = Loading
                , chartModel = Nothing
              }
            , Cmd.batch
                [ Endpoints.getRaceDetails model.year model.round GotRaceDetails
                , Endpoints.getDriverOrder model.year model.round GotDriverOrder
                , Endpoints.getPositionChanges model.year model.round GotPositionChanges
                , Endpoints.getRaceHighlights model.year model.round GotRaceHighlights
                ]
            )



-- VIEW


view : Model -> Html Msg
view model =
    Html.div
        []
        [ viewBackButton model.year
        , Html.div
            [ css
                [ displayFlex
                , property "gap" "2rem"
                , alignItems flexStart
                ]
            ]
            [ viewDriverList model.driverOrder
            , Html.div
                [ css
                    [ flex (int 1)
                    ]
                ]
                [ viewRaceContent model
                ]
            ]
        ]


viewBackButton : Int -> Html msg
viewBackButton year =
    Html.div
        [ css [ marginBottom (rem 1.5) ]
        ]
        [ Html.a
            [ Route.href (Route.RaceOverview year)
            , css
                [ display inlineFlex
                , alignItems center
                , property "gap" "0.5rem"
                , color (rgba 255 255 255 0.8)
                , textDecoration none
                , fontSize (rem 0.9)
                , padding2 (rem 0.5) (rem 0.75)
                , borderRadius (px 8)
                , backgroundColor (rgba 255 255 255 0.05)
                , border3 (px 1) solid (rgba 255 255 255 0.1)
                , property "transition" "all 0.2s"
                , hover
                    [ color (hex "#ffffff")
                    , backgroundColor (rgba 255 255 255 0.1)
                    , transform (translateX (px -2))
                    ]
                ]
            ]
            [ Html.span
                [ css
                    [ fontSize (rem 1.1)
                    ]
                ]
                [ Html.text "←" ]
            , Html.text "Back to races"
            ]
        ]


viewDriverList : RemoteData String DriverOrder -> Html msg
viewDriverList driverOrderData =
    Html.div
        [ css
            [ width (px 320)
            , flexShrink (int 0)
            ]
        ]
        [ case driverOrderData of
            Loading ->
                Skeleton.viewSkeletonRaceResults

            Success driverOrder ->
                viewDriverListContent driverOrder

            Failure _ ->
                Html.text ""
        ]


viewDriverListContent : DriverOrder -> Html msg
viewDriverListContent driverOrder =
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
        [ Html.h3
            [ css
                [ fontSize (rem 1.2)
                , fontWeight bold
                , marginBottom (rem 1)
                , color (hex "#ffffff")
                , textAlign left
                ]
            ]
            [ Html.text "Race Results" ]
        , Html.div
            [ css
                [ displayFlex
                , flexDirection column
                , property "gap" "0.5rem"
                ]
            ]
            (List.map viewDriverItem driverOrder.drivers)
        ]


viewDriverItem : Driver -> Html msg
viewDriverItem driver =
    let
        positionText =
            driver.position
                |> Maybe.map String.fromInt
                |> Maybe.withDefault "-"

        driverName =
            case ( driver.firstName, driver.lastName ) of
                ( Just first, Just last ) ->
                    first ++ " " ++ last

                ( Just first, Nothing ) ->
                    first

                ( Nothing, Just last ) ->
                    last

                ( Nothing, Nothing ) ->
                    driver.code |> Maybe.withDefault "Unknown"

        teamName =
            driver.team |> Maybe.withDefault "No Team"

        teamColorValue =
            driver.teamColor |> Maybe.withDefault "#ef4444"

        timeText =
            driver.time |> Maybe.withDefault ""

        isRetired =
            driver.status
                |> Maybe.map (\s -> s == "Retired")
                |> Maybe.withDefault False

        isLapped =
            driver.status
                |> Maybe.map (\s -> s == "Lapped")
                |> Maybe.withDefault False

        timeColor =
            if isLapped then
                rgba 255 100 100 0.8

            else if isRetired then
                rgba 150 150 150 0.8

            else
                rgba 255 255 255 0.8

        -- Clean up time format
        formattedTime =
            if isRetired && String.isEmpty timeText then
                "DNF"

            else if String.isEmpty timeText then
                ""

            else
                let
                    -- Remove "+-" prefix and "s" suffix from time
                    cleanTime =
                        timeText
                            |> String.replace "+-" ""
                            |> String.replace "s" ""
                in
                case driver.position of
                    Just 1 ->
                        cleanTime

                    _ ->
                        if String.startsWith "+" cleanTime then
                            cleanTime

                        else
                            "+" ++ cleanTime
    in
    Html.div
        [ css
            [ displayFlex
            , flexDirection column
            , padding2 (rem 0.75) (rem 1)
            , backgroundColor (rgba 20 15 30 0.5)
            , borderRadius (px 8)
            , borderLeft3 (px 4) solid (hex teamColorValue)
            , property "transition" "all 0.2s"
            , hover
                [ backgroundColor (rgba 30 25 40 0.7)
                , transform (translateX (px 2))
                ]
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , alignItems center
                ]
            ]
            [ Html.div
                [ css
                    [ width (px 28)
                    , height (px 28)
                    , displayFlex
                    , alignItems center
                    , justifyContent center
                    , fontSize (rem 0.85)
                    , fontWeight bold
                    , marginRight (rem 0.75)
                    , flexShrink (int 0)
                    , color (rgba 255 255 255 0.8)
                    ]
                ]
                [ Html.text positionText ]
            , Html.div
                [ css
                    [ fontSize (rem 0.95)
                    , fontWeight (int 600)
                    , color (hex "#ffffff")
                    , overflow hidden
                    , textOverflow ellipsis
                    , whiteSpace noWrap
                    , flex (int 1)
                    ]
                ]
                [ Html.text driverName ]
            ]
        , Html.div
            [ css
                [ displayFlex
                , alignItems center
                , justifyContent spaceBetween
                , marginLeft (px 40)
                , marginTop (rem 0.15)
                ]
            ]
            [ Html.div
                [ css
                    [ fontSize (rem 0.75)
                    , color (rgba 255 255 255 0.7)
                    , overflow hidden
                    , textOverflow ellipsis
                    , whiteSpace noWrap
                    ]
                ]
                [ Html.text teamName ]
            , Html.div
                [ css
                    [ fontSize (rem 0.75)
                    , color timeColor
                    , flexShrink (int 0)
                    , marginLeft (rem 0.5)
                    ]
                ]
                [ Html.text formattedTime ]
            ]
        ]


viewRaceContent : Model -> Html Msg
viewRaceContent model =
    case ( model.raceDetails, model.driverOrder ) of
        ( Loading, _ ) ->
            Skeleton.viewSkeletonLayout

        ( _, Loading ) ->
            Skeleton.viewSkeletonLayout

        ( Success _, _ ) ->
            viewRaceDetails model

        ( Failure error, _ ) ->
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
                [ color (rgba 255 255 255 0.7)
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


viewRaceDetails : Model -> Html Msg
viewRaceDetails model =
    case model.raceDetails of
        Success details ->
            Html.div []
                [ viewRaceHeader details
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
                        [ viewRaceHighlights model ]
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
                            [ viewRaceInfo details ]
                        , case details.weather of
                            Just weather ->
                                Html.div
                                    [ css
                                        [ flex (int 1)
                                        , minWidth (px 250)
                                        ]
                                    ]
                                    [ viewWeatherCard weather ]

                            Nothing ->
                                Html.text ""
                        ]
                    ]
                , viewPositionChart model
                ]

        _ ->
            Html.div [] []


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
                [ color (rgba 255 255 255 0.7)
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
            [ viewInfoItem "Date" (details.date |> Maybe.map toString |> Maybe.withDefault "N/A")
            , viewInfoItem "Total Laps" (String.fromInt details.totalLaps)
            , viewInfoItem "Race Duration" (Maybe.withDefault "N/A" details.raceDuration)
            , viewInfoItem "Circuit Length" (details.circuitLength |> Maybe.map (\len -> String.fromFloat len ++ " km") |> Maybe.withDefault "N/A")
            , viewInfoItem "Corners" (details.numCorners |> Maybe.map String.fromInt |> Maybe.withDefault "N/A")
            , viewInfoItem "Race Distance" (details.raceDistance |> Maybe.map (\dist -> String.fromFloat dist ++ " km") |> Maybe.withDefault "N/A")
            ]
        ]


viewInfoItem : String -> String -> Html msg
viewInfoItem label value =
    Html.div
        [ css
            [ flex (int 1)
            , minWidth (px 120)
            ]
        ]
        [ Html.div
            [ css
                [ color (rgba 255 255 255 0.7)
                , fontSize (rem 0.75)
                , marginBottom (rem 0.2)
                ]
            ]
            [ Html.text label ]
        , Html.div
            [ css
                [ color (hex "#ffffff")
                , fontSize (rem 1)
                , fontWeight bold
                ]
            ]
            [ Html.text value ]
        ]


viewWeatherCard : Weather -> Html msg
viewWeatherCard weather =
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
        [ Html.h3
            [ css
                [ fontSize (rem 1)
                , fontWeight bold
                , marginBottom (rem 0.75)
                , color (hex "#60a5fa")
                ]
            ]
            [ Html.text "Weather Conditions" ]
        , Html.div
            [ css
                [ displayFlex
                , flexWrap wrap
                , property "gap" "1rem"
                , flex (int 1)
                , alignItems center
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
            , minWidth (px 90)
            ]
        ]
        [ Html.div
            [ css
                [ color (rgba 255 255 255 0.7)
                , fontSize (rem 0.75)
                , marginBottom (rem 0.2)
                ]
            ]
            [ Html.text label ]
        , Html.div
            [ css
                [ color (hex "#ffffff")
                , fontSize (rem 1)
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


viewPositionChart : Model -> Html Msg
viewPositionChart model =
    case ( model.positionChanges, model.chartModel ) of
        ( Success changes, Just chartModel ) ->
            PositionChart.view chartModel changes
                |> Html.map ChartMsg

        ( Loading, _ ) ->
            Html.div
                [ css
                    [ backgroundColor (rgba 30 20 40 0.4)
                    , property "backdrop-filter" "blur(10px)"
                    , property "-webkit-backdrop-filter" "blur(10px)"
                    , border3 (px 1) solid (rgba 100 70 120 0.3)
                    , borderRadius (px 16)
                    , padding (rem 3)
                    , marginTop (rem 2)
                    , textAlign center
                    ]
                ]
                [ Spinner.viewWithText "Loading position chart" ]

        ( Failure error, _ ) ->
            Html.div
                [ css
                    [ backgroundColor (rgba 30 20 40 0.4)
                    , property "backdrop-filter" "blur(10px)"
                    , property "-webkit-backdrop-filter" "blur(10px)"
                    , border3 (px 1) solid (rgba 239 68 68 0.5)
                    , borderRadius (px 16)
                    , padding (rem 2)
                    , marginTop (rem 2)
                    , textAlign center
                    ]
                ]
                [ Html.h3
                    [ css
                        [ color (hex "#ef4444")
                        , fontSize (rem 1.2)
                        , marginBottom (rem 0.5)
                        ]
                    ]
                    [ Html.text "Position Chart Error" ]
                , Html.p
                    [ css
                        [ color (rgba 255 255 255 0.7)
                        , fontSize (rem 0.9)
                        ]
                    ]
                    [ Html.text error ]
                ]

        _ ->
            Html.text ""


viewRaceHighlights : Model -> Html Msg
viewRaceHighlights model =
    case model.raceHighlights of
        Success highlights ->
            RaceHighlights.view highlights

        Loading ->
            Html.div
                [ css
                    [ backgroundColor (rgba 30 20 40 0.4)
                    , property "backdrop-filter" "blur(10px)"
                    , property "-webkit-backdrop-filter" "blur(10px)"
                    , border3 (px 1) solid (rgba 100 70 120 0.3)
                    , borderRadius (px 16)
                    , padding (rem 3)
                    , marginTop (rem 2)
                    , textAlign center
                    ]
                ]
                [ Spinner.viewWithText "Loading race highlights..." ]

        Failure error ->
            Html.div
                [ css
                    [ backgroundColor (rgba 30 20 40 0.4)
                    , property "backdrop-filter" "blur(10px)"
                    , property "-webkit-backdrop-filter" "blur(10px)"
                    , border3 (px 1) solid (rgba 100 70 120 0.3)
                    , borderRadius (px 16)
                    , padding (rem 2)
                    , marginTop (rem 2)
                    ]
                ]
                [ Html.p
                    [ css
                        [ color (rgba 255 255 255 0.7)
                        , fontSize (rem 0.9)
                        ]
                    ]
                    [ Html.text ("Failed to load race highlights: " ++ error) ]
                ]
