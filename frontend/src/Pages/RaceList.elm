module Pages.RaceList exposing (Model, Msg, init, update, view)

import Components.Spinner as Spinner
import Css exposing (..)
import Endpoints exposing (loadRaces)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Http
import RemoteData exposing (RemoteData(..))
import Route
import Types.Date exposing (toString)
import Types.Race exposing (Race)
import Utils



-- MODEL


type alias Model =
    { races : RemoteData String (List Race)
    }


init : ( Model, Cmd Msg )
init =
    ( { races = Loading }
    , loadRaces GotRaces
    )



-- MSG


type Msg
    = GotRaces (Result Http.Error (List Race))



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotRaces result ->
            case result of
                Ok races ->
                    ( { model | races = Success races }, Cmd.none )

                Err error ->
                    ( { model | races = Failure (Utils.httpErrorToString error) }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ viewHeader
        , viewContent model
        ]


viewHeader : Html msg
viewHeader =
    Html.div
        [ css
            [ marginBottom (rem 2)
            ]
        ]
        [ Html.h1
            [ css
                [ fontSize (rem 2.5)
                , fontWeight bold
                , marginBottom (rem 0.5)
                , color (hex "#f1f5f9")
                ]
            ]
            [ Html.text "2024 Season Races" ]
        , Html.p
            [ css
                [ color (rgba 255 255 255 0.7)
                , fontSize (rem 1.1)
                ]
            ]
            [ Html.text "Click on any race to view detailed results and statistics" ]
        ]


viewContent : Model -> Html msg
viewContent model =
    case model.races of
        Loading ->
            Spinner.viewWithText "Loading races"

        Success races ->
            viewRaceList races

        Failure error ->
            viewError error


viewError : String -> Html msg
viewError error =
    Html.div
        [ css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 2)
            , color (hex "#c4b5d3")
            ]
        ]
        [ Html.h3
            [ css
                [ fontSize (rem 1.2)
                , fontWeight bold
                , marginBottom (rem 0.5)
                , color (hex "#ef4444")
                ]
            ]
            [ Html.text "Error loading races" ]
        , Html.p [] [ Html.text error ]
        ]


viewRaceList : List Race -> Html msg
viewRaceList races =
    Html.div
        [ css
            [ displayFlex
            , flexDirection column
            , property "gap" "1rem"
            ]
        ]
        (List.map viewRaceCard races)


viewRaceCard : Race -> Html msg
viewRaceCard race =
    Html.a
        [ Route.href (Route.RaceDetail (String.fromInt race.round))
        , css
            [ backgroundColor (rgba 30 20 40 0.4)
            , property "backdrop-filter" "blur(10px)"
            , property "-webkit-backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 100 70 120 0.3)
            , borderRadius (px 16)
            , padding (rem 2)
            , displayFlex
            , justifyContent spaceBetween
            , alignItems center
            , textDecoration none
            , color inherit
            , hover
                [ backgroundColor (rgba 30 20 40 0.6)
                , borderColor (rgba 239 68 68 0.4)
                ]
            , property "transition" "all 0.3s ease"
            , cursor pointer
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , alignItems center
                , property "gap" "1.5rem"
                ]
            ]
            [ Html.div
                [ css
                    [ color (hex "#ef4444")
                    , fontSize (rem 0.9)
                    , fontWeight bold
                    , minWidth (px 70)
                    ]
                ]
                [ Html.text ("Round " ++ String.fromInt race.round) ]
            , Html.div []
                [ Html.h3
                    [ css
                        [ fontSize (rem 1.2)
                        , fontWeight (int 600)
                        , marginBottom (rem 0.3)
                        , color (hex "#f1f5f9")
                        ]
                    ]
                    [ Html.text race.race ]
                , Html.div
                    [ css
                        [ fontSize (rem 0.9)
                        , color (rgba 255 255 255 0.7)
                        ]
                    ]
                    [ Html.text (race.date |> Maybe.map toString |> Maybe.withDefault "N/A") ]
                ]
            ]
        , Html.div
            [ css
                [ color (hex "#a0a8b8")
                , fontSize (rem 1.2)
                ]
            ]
            [ Html.text "→" ]
        ]
