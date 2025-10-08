module Main exposing (main)

import Browser
import Html exposing (Html, div, text)



-- MODEL


type alias Model =
    String



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( "Hello, F1 Dashboard!", Cmd.none )



-- MSG


type Msg
    = NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ text model ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
