module Main exposing (main)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Navigation
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Json.Decode as Json exposing (Value)
import Page.Create
import Page.Create.Message as CreateMessage
import Page.Create.Model
import Page.Edit
import Page.Edit.Message as EditMessage
import Page.Edit.Model
import Page.Home
import Page.Participate
import Page.Participate.Message as ParticipateMessage
import Page.Participate.Model
import Url exposing (Url)
import Url.Parser as UrlParser



---- MODEL ----


type alias Model =
    { page : Page
    , navKey : Navigation.Key
    }


type Page
    = Home Page.Home.Model
    | Create Page.Create.Model.Model
    | Edit Page.Edit.Model.Model
    | JsonError Json.Error
    | Participate Page.Participate.Model.Model


type Route
    = HomeRoute
    | CreateRoute
    | ParticipateRoute


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

        ParticipateRoute ->
            Page.Participate.init
                |> Tuple.mapFirst Participate
                |> Tuple.mapSecond (Cmd.map ParticipateMsg)



---- ROUTING ----


parseRoute : Url -> ( Page, Cmd Msg )
parseRoute url =
    UrlParser.parse routeParser url
        |> Maybe.withDefault HomeRoute
        |> initPage


routeParser : UrlParser.Parser (Route -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map ParticipateRoute UrlParser.top
        -- [ UrlParser.map HomeRoute UrlParser.top
        , UrlParser.map CreateRoute (UrlParser.s "neu")
        , UrlParser.map ParticipateRoute (UrlParser.s "aktion")
        ]



---- UPDATE ----


type Msg
    = NoOp
    | ClickedLink UrlRequest
    | UrlChanged Url
    | HomeMsg Page.Home.Msg
    | CreateMsg CreateMessage.Msg
    | EditMsg EditMessage.Msg
    | ParticipateMsg ParticipateMessage.Msg


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

        ( CreateMsg (CreateMessage.SubmitResponse (Ok value)), _ ) ->
            case Page.Edit.init value of
                Ok data ->
                    ( { model | page = Edit data }, Cmd.none )

                Err err ->
                    ( { model | page = JsonError err }, Cmd.none )

        ( CreateMsg msg_, Create data ) ->
            Page.Create.update msg_ data
                |> Tuple.mapFirst (\change -> { model | page = Create change })
                |> Tuple.mapSecond (Cmd.map CreateMsg)

        ( ParticipateMsg msg_, Participate data ) ->
            Page.Participate.update msg_ data
                |> Tuple.mapFirst (\change -> { model | page = Participate change })
                |> Tuple.mapSecond (Cmd.map ParticipateMsg)

        _ ->
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

            Edit data ->
                Page.Edit.view data
                    |> Html.map EditMsg

            Participate data ->
                Page.Participate.view data
                    |> Html.map ParticipateMsg

            JsonError error ->
                Html.pre [] [ Html.text (Json.errorToString error) ]
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
