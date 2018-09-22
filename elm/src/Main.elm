module Main exposing (main)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Navigation
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Json.Encode exposing (Value)
import Page.Create
import Page.Home
import Url exposing (Url)
import Url.Parser as UrlParser



---- MODEL ----


type alias Model =
    { page : Page
    , navKey : Navigation.Key
    }


type Page
    = Home Page.Home.Model
    | Create Page.Create.Model


type Route
    = HomeRoute
    | CreateRoute


init : Value -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( page, cmd ) =
            parseRoute url
    in
    ( { page = page
      , navKey = key
      }
    , cmd
    )


initPage : Route -> ( Page, Cmd Msg )
initPage route =
    case route of
        HomeRoute ->
            Page.Home.init
                |> Tuple.mapFirst Home
                |> Tuple.mapSecond (Cmd.map HomeMsg)

        CreateRoute ->
            Page.Create.init
                |> Tuple.mapFirst Create
                |> Tuple.mapSecond (Cmd.map CreateMsg)



---- ROUTING ----


parseRoute : Url -> ( Page, Cmd Msg )
parseRoute url =
    UrlParser.parse routeParser url
        |> Maybe.withDefault HomeRoute
        |> initPage


routeParser : UrlParser.Parser (Route -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map HomeRoute UrlParser.top
        , UrlParser.map CreateRoute (UrlParser.s "neu")
        ]



---- UPDATE ----


type Msg
    = NoOp
    | ClickedLink UrlRequest
    | UrlChanged Url
    | HomeMsg Page.Home.Msg
    | CreateMsg Page.Create.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Navigation.pushUrl model.navKey (Url.toString url)
                    )

                External url ->
                    -- TODO store form state?
                    ( model
                    , Navigation.load url
                    )

        ( UrlChanged url, _ ) ->
            parseRoute url
                |> Tuple.mapFirst (\page -> { model | page = page })

        ( HomeMsg msg_, Home data ) ->
            Page.Home.update msg_ data
                |> Tuple.mapFirst (\change -> { model | page = Home change })
                |> Tuple.mapSecond (Cmd.map HomeMsg)

        ( CreateMsg msg_, Create data ) ->
            Page.Create.update msg_ data
                |> Tuple.mapFirst (\change -> { model | page = Create change })
                |> Tuple.mapSecond (Cmd.map CreateMsg)

        _ ->
            let
                _ =
                    Debug.log "unknown" ( msg, model.page )
            in
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "Wichteln"
    , body =
        [ case model.page of
            Home data ->
                Page.Home.view data
                    |> Html.map HomeMsg

            Create data ->
                Page.Create.view data
                    |> Html.map CreateMsg
        ]
    }



---- PROGRAM ----


main : Program Value Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = ClickedLink
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
