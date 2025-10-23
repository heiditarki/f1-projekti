module Route exposing (Route(..), fromUrl, href, toString)

import Html.Styled as Html exposing (Attribute)
import Html.Styled.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


type Route
    = Home
    | RaceOverview
    | RaceDetail String
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map RaceOverview (s "races")
        , Parser.map RaceDetail (s "race" </> string)
        ]


fromUrl : Url -> Route
fromUrl url =
    Parser.parse parser url
        |> Maybe.withDefault NotFound


toString : Route -> String
toString route =
    case route of
        Home ->
            "/"

        RaceOverview ->
            "/races"

        RaceDetail id ->
            "/race/" ++ id

        NotFound ->
            "/404"


href : Route -> Attribute msg
href route =
    Attr.href (toString route)
