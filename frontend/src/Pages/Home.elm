module Pages.Home exposing (Model, Msg, init, subscriptions, update, view)

import Components.Countdown as Countdown
import Css exposing (..)
import Endpoints
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Http
import RemoteData exposing (RemoteData(..))
import Route
import Time
import Types.NextRace as NextRace
import Utils



-- MODEL


type alias Model =
    { nextRace : RemoteData String NextRace.NextRace
    }


init : ( Model, Cmd Msg )
init =
    ( { nextRace = Loading }
    , Endpoints.loadNextRace GotNextRace
    )



-- MSG


type Msg
    = GotNextRace (Result Http.Error NextRace.NextRace)
    | Tick



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotNextRace result ->
            case result of
                Ok nextRace ->
                    ( { model | nextRace = Success nextRace }, Cmd.none )

                Err error ->
                    ( { model | nextRace = Failure (Utils.httpErrorToString error) }, Cmd.none )

        Tick ->
            ( { model | nextRace = tickNextRace model.nextRace }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.nextRace of
        Success nextRace ->
            case nextRace.countdown of
                Just _ ->
                    Time.every 1000 (\_ -> Tick)

                Nothing ->
                    Sub.none

        _ ->
            Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Html.div
        [ css
            [ color (hex "#ffffff")
            , position relative
            , minHeight (vh 100)
            ]
        ]
        [ viewHero
        , viewCountdownSection model.nextRace
        , viewGlassCard
        , viewActionCards
        ]


viewCountdownSection : RemoteData String NextRace.NextRace -> Html Msg
viewCountdownSection nextRaceData =
    Html.section
        [ css
            [ padding2 (rem 5) (rem 2)
            , displayFlex
            , justifyContent center
            ]
        ]
        [ case nextRaceData of
            Loading ->
                viewCountdownLoading

            Failure error ->
                viewCountdownError error

            Success nextRace ->
                Countdown.view (countdownProps nextRace)
        ]


viewCountdownLoading : Html msg
viewCountdownLoading =
    Html.div
        [ css
            [ backgroundColor (rgba 255 255 255 0.03)
            , border3 (px 1) solid (rgba 255 255 255 0.08)
            , borderRadius (px 16)
            , padding2 (rem 2) (rem 3)
            , color (hex "#aaaaaa")
            , textAlign center
            , width (pct 100)
            , maxWidth (px 600)
            ]
        ]
        [ Html.text "Loading next race details..." ]


viewCountdownError : String -> Html msg
viewCountdownError message =
    Html.div
        [ css
            [ backgroundColor (rgba 127 29 29 0.2)
            , border3 (px 1) solid (rgba 239 68 68 0.4)
            , borderRadius (px 16)
            , padding2 (rem 2) (rem 3)
            , color (hex "#fca5a5")
            , textAlign center
            , width (pct 100)
            , maxWidth (px 600)
            ]
        ]
        [ Html.text message ]


countdownProps : NextRace.NextRace -> Countdown.Props Msg
countdownProps nextRace =
    { countdown = nextRace.countdown
    , raceName = nextRace.raceName
    , officialName = nextRace.officialName
    , circuit = nextRace.circuit
    , country = nextRace.country
    , actionAttributes = []
    , actionLabel = ""
    }


tickNextRace : RemoteData String NextRace.NextRace -> RemoteData String NextRace.NextRace
tickNextRace remoteData =
    case remoteData of
        Success nextRace ->
            let
                updatedCountdown =
                    Maybe.map NextRace.decrement nextRace.countdown
            in
            Success { nextRace | countdown = updatedCountdown }

        _ ->
            remoteData


viewHero : Html msg
viewHero =
    Html.section
        [ Attr.class "hero-section"
        , css
            [ position relative
            , minHeight (vh 100)
            , displayFlex
            , alignItems center
            , justifyContent flexStart
            , flexDirection column
            , paddingTop (rem 4)
            , paddingBottom (rem 8)
            ]
        ]
        [ Html.div
            [ Attr.class "hero-section__content"
            , css
                [ textAlign center
                , padding (rem 2)
                , width (pct 100)
                , displayFlex
                , flexDirection column
                , alignItems center
                ]
            ]
            [ Html.h1
                [ Attr.class "hero-section__title"
                , css
                    [ fontWeight bold
                    , marginBottom (rem 1)
                    , letterSpacing (px 2)
                    , property "text-shadow" "0 4px 30px rgba(239, 68, 68, 0.6)"
                    , property "font-size" "clamp(2.4rem, 8vw, 5.5rem)"
                    , color (hex "#ffffff")
                    ]
                ]
                [ Html.span [ css [ color (hex "#ef4444") ] ] [ Html.text "F1" ]
                , Html.br [] []
                , Html.text "DASHBOARD"
                ]
            , Html.div
                [ Attr.class "hero-section__tagline"
                , css
                    [ property "font-size" "clamp(0.85rem, 3vw, 1.1rem)"
                    , color (hex "#aaaaaa")
                    , property "letter-spacing" "0.35rem"
                    , textTransform uppercase
                    , marginTop (rem 2)
                    , alignSelf center
                    ]
                ]
                [ Html.text "All Seasons" ]
            , Html.div
                [ Attr.class "hero-section__scroll"
                , css
                    [ property "margin-top" "clamp(4rem, 12vh, 10rem)"
                    , property "font-size" "clamp(1.5rem, 4vw, 2rem)"
                    , color (hex "#ef4444")
                    , property "animation" "bounce 2s ease-in-out infinite"
                    , cursor pointer
                    ]
                ]
                [ Html.text "↓" ]
            ]
        , -- CSS animations
          Html.node "style"
            []
            [ Html.text """
                 @keyframes bounce {
                     0%, 100% { transform: translateY(0); }
                     50% { transform: translateY(-15px); }
                 }
             """
            ]
        ]


viewGlassCard : Html msg
viewGlassCard =
    Html.section
        [ Attr.class "glass-card-section"
        , css
            [ padding2 (rem 6) (rem 2)
            , displayFlex
            , justifyContent center
            , alignItems center
            ]
        ]
        [ Html.div
            [ Attr.class "glass-card"
            , css
                [ maxWidth (px 900)
                , width (pct 90)
                , backgroundColor (rgba 255 255 255 0.05)
                , property "backdrop-filter" "blur(10px)"
                , border3 (px 1) solid (rgba 255 255 255 0.1)
                , borderRadius (px 20)
                , padding (rem 4)
                , paddingTop (rem 5)
                , property "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.3)"
                , property "transition" "transform 0.3s ease"
                , hover
                    [ transform (translateY (px -5))
                    ]
                ]
            ]
            [ Html.h2
                [ css
                    [ fontSize (rem 2.5)
                    , fontWeight bold
                    , marginBottom (rem 2)
                    , textAlign center
                    , color (hex "#ffffff")
                    ]
                ]
                [ Html.text "About F1 Dashboard" ]
            , Html.p
                [ css
                    [ fontSize (rem 1.2)
                    , lineHeight (num 1.8)
                    , color (hex "#cccccc")
                    , marginBottom (rem 2)
                    , textAlign center
                    ]
                ]
                [ Html.text "Your hub for exploring historical and upcoming Formula 1 races with concise data, highlights, and schedule snapshots." ]
            , Html.div
                [ css
                    [ height (px 1)
                    , backgroundColor (rgba 255 255 255 0.1)
                    , margin2 (rem 3) zero
                    ]
                ]
                []
            , Html.div
                [ css
                    [ textAlign center
                    ]
                ]
                [ Html.p
                    [ css
                        [ fontSize (rem 1)
                        , color (hex "#888888")
                        , marginBottom (rem 0.5)
                        ]
                    ]
                    [ Html.text "Built with Elm for F1 fans" ]
                , Html.p
                    [ css
                        [ fontSize (rem 0.95)
                        , color (hex "#888888")
                        , marginBottom (rem 1.5)
                        ]
                    ]
                    [ Html.text "Powered by "
                    , Html.a
                        [ Attr.href "https://docs.fastf1.dev/"
                        , Attr.target "_blank"
                        , css
                            [ color (hex "#ef4444")
                            , textDecoration none
                            , hover
                                [ textDecoration underline
                                ]
                            ]
                        ]
                        [ Html.text "FastF1 API" ]
                    ]
                , Html.div
                    [ css
                        [ fontSize (rem 1.1)
                        , color (hex "#ffffff")
                        ]
                    ]
                    [ Html.text "Created by "
                    , Html.a
                        [ Attr.href "https://github.com/heiditarki"
                        , Attr.target "_blank"
                        , css
                            [ color (hex "#ef4444")
                            , textDecoration none
                            , fontWeight bold
                            , hover
                                [ textDecoration underline
                                ]
                            ]
                        ]
                        [ Html.text "Heidi Tarkiainen" ]
                    ]
                ]
            ]
        ]


viewActionCards : Html msg
viewActionCards =
    Html.section
        [ css
            [ padding2 (rem 6) (rem 2)
            , paddingBottom (rem 10)
            ]
        ]
        [ Html.div
            [ css
                [ maxWidth (px 1200)
                , margin2 zero auto
                ]
            ]
            [ Html.h2
                [ css
                    [ fontSize (rem 3)
                    , fontWeight bold
                    , textAlign center
                    , marginBottom (rem 2.5)
                    , color (hex "#ffffff")
                    ]
                ]
                [ Html.text "Get Started" ]
            , Html.div
                [ css
                    [ property "display" "grid"
                    , property "grid-template-columns" "repeat(auto-fit, minmax(260px, 1fr))"
                    , property "gap" "2rem"
                    , marginTop (rem 1.5)
                    ]
                ]
                [ viewActionCard
                    "🏁"
                    "Browse Races"
                    "Jump into race weekends and explore sessions, drivers, and results."
                    (Route.RaceOverview 2025)
                , viewInfoPanel
                ]
            ]
        ]


viewActionCard : String -> String -> String -> Route.Route -> Html msg
viewActionCard icon title description route =
    Html.a
        [ Route.href route
        , css
            [ backgroundColor (rgba 255 255 255 0.03)
            , property "backdrop-filter" "blur(10px)"
            , border3 (px 1) solid (rgba 255 255 255 0.08)
            , borderRadius (px 16)
            , padding (rem 3)
            , textDecoration none
            , color (hex "#ffffff")
            , display block
            , maxWidth (px 420)
            , property "transition" "all 0.3s ease"
            , hover
                [ backgroundColor (rgba 239 68 68 0.1)
                , borderColor (hex "#ef4444")
                , transform (translateY (px -8))
                , property "box-shadow" "0 12px 40px rgba(239, 68, 68, 0.3)"
                ]
            ]
        ]
        [ Html.div
            [ css
                [ fontSize (rem 3.5)
                , marginBottom (rem 1)
                , textAlign center
                ]
            ]
            [ Html.text icon ]
        , Html.h3
            [ css
                [ fontSize (rem 1.8)
                , fontWeight bold
                , marginBottom (rem 1)
                , textAlign center
                ]
            ]
            [ Html.text title ]
        , Html.p
            [ css
                [ fontSize (rem 1)
                , color (hex "#aaaaaa")
                , lineHeight (num 1.6)
                , textAlign center
                ]
            ]
            [ Html.text description ]
        , Html.div
            [ css
                [ textAlign center
                , marginTop (rem 1.5)
                , fontSize (rem 0.95)
                , color (hex "#ef4444")
                , fontWeight (int 600)
                ]
            ]
            [ Html.text "Let's Go →" ]
        ]


viewInfoPanel : Html msg
viewInfoPanel =
    Html.div
        [ css
            [ backgroundColor (rgba 255 255 255 0.03)
            , border3 (px 1) solid (rgba 255 255 255 0.1)
            , borderRadius (px 16)
            , padding (rem 3)
            , color (hex "#ffffff")
            , property "backdrop-filter" "blur(10px)"
            , property "box-shadow" "0 10px 40px rgba(15, 23, 42, 0.35)"
            , displayFlex
            , flexDirection column
            , property "gap" "1.2rem"
            ]
        ]
        [ Html.h3
            [ css
                [ fontSize (rem 1.6)
                , fontWeight bold
                , marginBottom (rem 0.5)
                , textAlign center
                ]
            ]
            [ Html.text "Need a pit strategy?" ]
        , Html.ul
            [ css
                [ listStyleType none
                , padding zero
                , margin zero
                , displayFlex
                , flexDirection column
                , property "gap" "0.75rem"
                , color (rgba 255 255 255 0.8)
                , fontSize (rem 1)
                ]
            ]
            [ viewBullet "Track upcoming race countdowns at a glance"
            , viewBullet "Go deep with circuit, driver, and session insights"
            , viewBullet "Compare seasons with historical context"
            ]
        , Html.div
            [ css
                [ displayFlex
                , justifyContent center
                , property "gap" "1rem"
                ]
            ]
            [ viewInfoLink "View API Docs" "https://docs.fastf1.dev/"
            , viewInfoLink "Project Repository" "https://github.com/heiditarki/f1-projekti"
            ]
        ]


viewBullet : String -> Html msg
viewBullet message =
    Html.li
        [ css
            [ displayFlex
            , alignItems center
            , property "gap" "0.6rem"
            ]
        ]
        [ Html.span
            [ css
                [ color (hex "#ef4444")
                , fontSize (rem 1.2)
                , fontWeight bold
                ]
            ]
            [ Html.text "•" ]
        , Html.span [] [ Html.text message ]
        ]


viewInfoLink : String -> String -> Html msg
viewInfoLink label url =
    Html.a
        [ Attr.href url
        , Attr.target "_blank"
        , css
            [ backgroundColor (rgba 239 68 68 0.12)
            , color (hex "#ef4444")
            , textDecoration none
            , fontSize (rem 0.9)
            , fontWeight (int 600)
            , borderRadius (px 999)
            , padding2 (rem 0.5) (rem 1.2)
            , property "display" "inline-flex"
            , alignItems center
            , property "gap" "0.4rem"
            , property "transition" "all 0.2s ease"
            , hover
                [ backgroundColor (rgba 239 68 68 0.24)
                , color (hex "#ffffff")
                ]
            ]
        ]
        [ Html.text label
        , Html.span [] [ Html.text "↗" ]
        ]
