module Components.PositionChart exposing (Model, Msg, init, update, view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css, type_)
import Html.Styled.Events exposing (onCheck)
import Set exposing (Set)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Types.PositionChanges exposing (DriverPosition, PositionChanges)



-- MODEL


type alias Model =
    { selectedDrivers : Set String
    , isExpanded : Bool
    }


init : PositionChanges -> Model
init data =
    { selectedDrivers =
        data.drivers
            |> List.take 5
            |> List.filterMap .code
            |> Set.fromList
    , isExpanded = True
    }



-- MSG


type Msg
    = ToggleDriver String Bool
    | ToggleExpand



-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleDriver code isChecked ->
            { model
                | selectedDrivers =
                    if isChecked then
                        Set.insert code model.selectedDrivers

                    else
                        Set.remove code model.selectedDrivers
            }

        ToggleExpand ->
            { model | isExpanded = not model.isExpanded }



-- Configuration


config : { width : number, height : number, marginTop : number, marginRight : number, marginBottom : number, marginLeft : number, maxPosition : number }
config =
    { width = 1000
    , height = 600
    , marginTop = 40
    , marginRight = 100
    , marginBottom = 40
    , marginLeft = 60
    , maxPosition = 20
    }



-- Calculate chart dimensions


chartWidth : Float
chartWidth =
    toFloat config.width - config.marginLeft - config.marginRight


chartHeight : Float
chartHeight =
    toFloat config.height - config.marginTop - config.marginBottom



-- View function


view : Model -> PositionChanges -> Html Msg
view model data =
    let
        visibleDrivers =
            data.drivers
                |> List.filter
                    (\driver ->
                        driver.code
                            |> Maybe.map (\code -> Set.member code model.selectedDrivers)
                            |> Maybe.withDefault False
                    )
    in
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
        [ Html.div
            [ css
                [ displayFlex
                , justifyContent spaceBetween
                , alignItems center
                , marginBottom
                    (if model.isExpanded then
                        rem 1.5

                     else
                        rem 0
                    )
                , cursor pointer
                ]
            , Html.Styled.Events.onClick ToggleExpand
            ]
            [ Html.h3
                [ css
                    [ fontSize (rem 1.3)
                    , fontWeight bold
                    , color (hex "#ffffff")
                    , margin zero
                    ]
                ]
                [ Html.text "Position Changes" ]
            , Html.span
                [ css
                    [ fontSize (rem 1.2)
                    , color (rgba 255 255 255 0.5)
                    , property "transition" "transform 0.2s"
                    , transform
                        (if model.isExpanded then
                            rotate (deg 180)

                         else
                            rotate (deg 0)
                        )
                    ]
                ]
                [ Html.text "▼" ]
            ]
        , if model.isExpanded then
            Html.div []
                [ viewDriverSelection model data.drivers
                , Html.div
                    [ css
                        [ marginTop (rem 1.5)
                        , overflowX auto
                        ]
                    ]
                    [ Svg.svg
                        [ SvgAttr.width (String.fromInt config.width)
                        , SvgAttr.height (String.fromInt config.height)
                        , SvgAttr.viewBox ("0 0 " ++ String.fromInt config.width ++ " " ++ String.fromInt config.height)
                        ]
                        (List.concat
                            [ [ gridLines data.totalLaps ]
                            , [ yAxisLabels ]
                            , [ xAxisLabels data.totalLaps ]
                            , List.map (driverLine data.totalLaps) visibleDrivers
                            ]
                        )
                    ]
                ]

          else
            Html.text ""
        ]


viewDriverSelection : Model -> List DriverPosition -> Html Msg
viewDriverSelection model drivers =
    Html.div
        [ css
            [ displayFlex
            , flexWrap wrap
            , property "gap" "0.4rem"
            , marginBottom (rem 1.5)
            ]
        ]
        (drivers
            |> List.map
                (\driver ->
                    let
                        driverCode =
                            driver.code |> Maybe.withDefault "?"

                        teamColorValue =
                            driver.teamColor
                                |> Maybe.withDefault "ef4444"

                        isSelected =
                            Set.member driverCode model.selectedDrivers
                    in
                    Html.label
                        [ css
                            [ displayFlex
                            , alignItems center
                            , padding2 (rem 0.3) (rem 0.5)
                            , backgroundColor (rgba 20 15 30 0.4)
                            , borderRadius (px 4)
                            , borderLeft3 (px 2) solid (hex teamColorValue)
                            , cursor pointer
                            , property "transition" "opacity 0.2s"
                            , opacity
                                (if isSelected then
                                    num 1

                                 else
                                    num 0.4
                                )
                            , hover [ opacity (num 1) ]
                            ]
                        ]
                        [ Html.input
                            [ type_ "checkbox"
                            , Attr.checked isSelected
                            , onCheck (ToggleDriver driverCode)
                            , css
                                [ marginRight (rem 0.3)
                                , cursor pointer
                                ]
                            ]
                            []
                        , Html.span
                            [ css
                                [ fontSize (rem 0.75)
                                , color (hex "#ffffff")
                                , fontWeight (int 500)
                                ]
                            ]
                            [ Html.text driverCode ]
                        ]
                )
        )



-- Grid lines (horizontal for each position)


gridLines : Int -> Svg msg
gridLines _ =
    Svg.g []
        (List.range 1 config.maxPosition
            |> List.map
                (\pos ->
                    let
                        y =
                            positionToY pos
                    in
                    Svg.line
                        [ SvgAttr.x1 (String.fromFloat config.marginLeft)
                        , SvgAttr.y1 (String.fromFloat y)
                        , SvgAttr.x2 (String.fromFloat (config.marginLeft + chartWidth))
                        , SvgAttr.y2 (String.fromFloat y)
                        , SvgAttr.stroke "#e5e7eb"
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.strokeOpacity "0.2"
                        ]
                        []
                )
        )



-- Y-axis labels (P1, P2, P3, ...)


yAxisLabels : Svg msg
yAxisLabels =
    Svg.g []
        (List.range 1 config.maxPosition
            |> List.map
                (\pos ->
                    Svg.text_
                        [ SvgAttr.x (String.fromFloat (config.marginLeft - 10))
                        , SvgAttr.y (String.fromFloat (positionToY pos + 5))
                        , SvgAttr.textAnchor "end"
                        , SvgAttr.fontSize "12"
                        , SvgAttr.fill "#9ca3af"
                        ]
                        [ Svg.text ("P" ++ String.fromInt pos) ]
                )
        )



-- X-axis labels (lap numbers)


xAxisLabels : Int -> Svg msg
xAxisLabels totalLaps =
    let
        -- Show labels every 5 laps
        lapInterval =
            5

        laps =
            List.range 0 (totalLaps // lapInterval)
                |> List.map (\i -> i * lapInterval)
                |> List.filter (\lap -> lap > 0 && lap <= totalLaps)
    in
    Svg.g []
        (laps
            |> List.map
                (\lap ->
                    Svg.text_
                        [ SvgAttr.x (String.fromFloat (lapToX lap totalLaps))
                        , SvgAttr.y (String.fromFloat (config.marginTop + chartHeight + 25))
                        , SvgAttr.textAnchor "middle"
                        , SvgAttr.fontSize "12"
                        , SvgAttr.fill "#9ca3af"
                        ]
                        [ Svg.text ("L" ++ String.fromInt lap) ]
                )
        )



-- Draw a line for one driver


driverLine : Int -> DriverPosition -> Svg msg
driverLine totalLaps driver =
    let
        color =
            driver.teamColor
                |> Maybe.withDefault "999999"
                |> (\c -> "#" ++ c)

        -- Convert positions to points
        points =
            driver.positions
                |> List.indexedMap
                    (\lapIndex maybePos ->
                        maybePos
                            |> Maybe.map
                                (\pos ->
                                    { lap = lapIndex + 1
                                    , position = pos
                                    , x = lapToX (lapIndex + 1) totalLaps
                                    , y = positionToY pos
                                    }
                                )
                    )
                |> List.filterMap identity

        -- Create path string
        pathData =
            points
                |> List.indexedMap
                    (\i point ->
                        if i == 0 then
                            "M " ++ String.fromFloat point.x ++ " " ++ String.fromFloat point.y

                        else
                            " L " ++ String.fromFloat point.x ++ " " ++ String.fromFloat point.y
                    )
                |> String.concat
    in
    Svg.g []
        [ Svg.path
            [ SvgAttr.d pathData
            , SvgAttr.stroke color
            , SvgAttr.strokeWidth "2.5"
            , SvgAttr.fill "none"
            , SvgAttr.strokeOpacity "0.9"
            ]
            []

        -- Add driver code label at the end
        , case List.reverse points |> List.head of
            Just lastPoint ->
                Svg.text_
                    [ SvgAttr.x (String.fromFloat (lastPoint.x + 10))
                    , SvgAttr.y (String.fromFloat (lastPoint.y + 5))
                    , SvgAttr.fontSize "11"
                    , SvgAttr.fontWeight "600"
                    , SvgAttr.fill color
                    ]
                    [ Svg.text (driver.code |> Maybe.withDefault "?") ]

            Nothing ->
                Svg.text_ [] []
        ]



-- Helper: Convert position (1-20) to Y coordinate


positionToY : Int -> Float
positionToY position =
    let
        step =
            chartHeight / toFloat (config.maxPosition - 1)
    in
    config.marginTop + (toFloat (position - 1) * step)



-- Helper: Convert lap number to X coordinate


lapToX : Int -> Int -> Float
lapToX lap totalLaps =
    let
        step =
            chartWidth / toFloat totalLaps
    in
    config.marginLeft + (toFloat lap * step)
