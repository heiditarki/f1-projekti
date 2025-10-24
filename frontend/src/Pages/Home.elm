module Pages.Home exposing (Model, Msg, init, update, view)

import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Route



-- MODEL


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



-- MSG


type Msg
    = NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view _ =
    Html.div
        [ css
            [ minHeight (vh 100)
            , displayFlex
            , flexDirection column
            , alignItems center
            , justifyContent center
            , textAlign center
            , padding (rem 4)
            ]
        ]
        [ viewNavigation
        ]


viewNavigation : Html msg
viewNavigation =
    Html.a
        [ Route.href (Route.RaceOverview 2025)
        , css
            [ backgroundColor (hex "#ef4444")
            , color (hex "#ffffff")
            , fontSize (rem 1.2)
            , fontWeight bold
            , textDecoration none
            , padding2 (rem 1) (rem 2)
            , borderRadius (px 8)
            , border zero
            , cursor pointer
            , hover
                [ backgroundColor (hex "#dc2626")
                , transform (scale 1.05)
                ]
            , property "transition" "all 0.2s ease"
            , property "box-shadow" "0 4px 12px rgba(239, 68, 68, 0.3)"
            ]
        ]
        [ Html.text "View Races" ]
