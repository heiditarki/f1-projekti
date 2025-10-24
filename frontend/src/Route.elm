module Route exposing (Route(..), fromUrl, href)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, int, oneOf, s, string)


type Route
    = Home
    | RaceOverview Int
    | RaceDetail Int String
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map RaceOverview (s "races" </> int)
        , Parser.map RaceDetail (s "race" </> int </> string)
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

        RaceOverview year ->
            "/races/" ++ String.fromInt year

        RaceDetail year id ->
            "/race/" ++ String.fromInt year ++ "/" ++ id

        NotFound ->
            "/404"


href : Route -> Attribute msg
href route =
    Attr.href (toString route)
