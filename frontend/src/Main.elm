module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Components.Header as Header
import Css exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Pages.Home as Home
import Pages.RaceDetails as RaceDetails
import Pages.RaceList as RaceList
import Route exposing (Route)
import Url exposing (Url)



-- MODEL


type alias Model =
    { navKey : Nav.Key
    , route : Route
    , page : Page
    }


type Page
    = HomePage Home.Model
    | RaceListPage RaceList.Model
    | RaceDetailPage RaceDetails.Model
    | NotFoundPage


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    let
        route =
            Route.fromUrl url

        ( page, cmd ) =
            initPage route
    in
    ( { navKey = navKey
      , route = route
      , page = page
      }
    , cmd
    )


initPage : Route -> ( Page, Cmd Msg )
initPage route =
    case route of
        Route.Home ->
            let
                ( model, cmd ) =
                    Home.init
            in
            ( HomePage model, Cmd.map HomeMsg cmd )

        Route.RaceOverview _ ->
            let
                ( model, cmd ) =
                    RaceList.init
            in
            ( RaceListPage model, Cmd.map RaceListMsg cmd )

        Route.RaceDetail year id ->
            let
                ( model, cmd ) =
                    RaceDetails.init year id
            in
            ( RaceDetailPage model, Cmd.map RaceDetailMsg cmd )

        _ ->
            ( NotFoundPage, Cmd.none )



-- MSG


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | HomeMsg Home.Msg
    | RaceListMsg RaceList.Msg
    | RaceDetailMsg RaceDetails.Msg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                route =
                    Route.fromUrl url

                ( page, cmd ) =
                    initPage route
            in
            ( { model | route = route, page = page }, cmd )

        HomeMsg homeMsg ->
            case model.page of
                HomePage homeModel ->
                    let
                        ( updatedModel, cmd ) =
                            Home.update homeMsg homeModel
                    in
                    ( { model | page = HomePage updatedModel }
                    , Cmd.map HomeMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        RaceListMsg listMsg ->
            case model.page of
                RaceListPage listModel ->
                    let
                        ( updatedModel, cmd ) =
                            RaceList.update listMsg listModel
                    in
                    ( { model | page = RaceListPage updatedModel }
                    , Cmd.map RaceListMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        RaceDetailMsg detailMsg ->
            case model.page of
                RaceDetailPage detailModel ->
                    let
                        ( updatedModel, cmd ) =
                            RaceDetails.update detailMsg detailModel
                    in
                    ( { model | page = RaceDetailPage updatedModel }
                    , Cmd.map RaceDetailMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "F1 Dashboard"
    , body =
        [ Html.toUnstyled <|
            Html.div
                [ css
                    [ minHeight (vh 100)
                    , color (hex "#f1f5f9")
                    , fontFamilies [ "system-ui", "-apple-system", "sans-serif" ]
                    ]
                ]
                [ Header.view
                , Html.main_
                    [ css
                        [ maxWidth (px 1400)
                        , margin2 zero auto
                        , padding (rem 2)
                        , paddingTop (rem 6)
                        ]
                    ]
                    [ viewPage model ]
                ]
        ]
    }


viewPage : Model -> Html Msg
viewPage model =
    case model.page of
        HomePage homeModel ->
            Html.map HomeMsg (Home.view homeModel)

        RaceListPage listModel ->
            Html.map RaceListMsg (RaceList.view listModel)

        RaceDetailPage detailModel ->
            Html.map RaceDetailMsg (RaceDetails.view detailModel)

        NotFoundPage ->
            viewNotFound


viewNotFound : Html msg
viewNotFound =
    Html.div
        [ css
            [ textAlign center
            , padding (rem 4)
            ]
        ]
        [ Html.h2
            [ css
                [ fontSize (rem 2)
                , marginBottom (rem 1)
                ]
            ]
            [ Html.text "404 - Page not found" ]
        , Html.a
            [ Route.href (Route.RaceOverview 2025)
            , css
                [ color (hex "#ef4444")
                , textDecoration none
                , hover [ textDecoration underline ]
                ]
            ]
            [ Html.text "← Back to races" ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
