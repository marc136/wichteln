module Main exposing (Model, Msg(..), init, main, update, view)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Json
import Participate
import Participate.Message as Participate
import Participate.Model as Participate
import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>))



---- MODEL ----


type alias Model =
    { page : Page
    , navKey : Navigation.Key
    , self : String
    , participants : List String
    }


type Page
    = LoginForm String
    | Waiting
    | Result Participate.Model
    | LoginError Http.Error


type Route
    = Login
    | LoginWithName String


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { page = LoginForm ""
      , navKey = key
      , self = flags.random
      , participants = List.sort flags.participants
      }
        |> routeToPage url
    , Cmd.none
    )


routeToPage : Url -> Model -> Model
routeToPage url model =
    let
        self =
            case UrlParser.parse routeParser url of
                Just (LoginWithName self_) ->
                    case Url.percentDecode self_ of
                        Just decoded ->
                            decoded

                        Nothing ->
                            model.self

                _ ->
                    model.self
    in
    { model | page = LoginForm "", self = self }


routeParser : UrlParser.Parser (Route -> Route) Route
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Login UrlParser.top
        , UrlParser.map Login (UrlParser.s "wichteln_2018" </> UrlParser.top)
        , UrlParser.map Login (UrlParser.s "wichteln_2018")
        , UrlParser.map LoginWithName UrlParser.string
        , UrlParser.map LoginWithName (UrlParser.s "wichteln_2018" </> UrlParser.string)
        ]


type alias Flags =
    { random : String
    , participants : List String
    }



---- UPDATE ----


type Msg
    = NoOp
    | ClickedLink UrlRequest
    | UrlChanged Url
      -- Login form
    | EnteredPassword String
    | SelectedParticipant String
    | SubmitLogin
    | LoginResponse (Result Http.Error LoginSuccess)
    | LoginAgain
      -- Participate
    | ParticipateMsg Participate.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ClickedLink urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Navigation.pushUrl model.navKey (Url.toString url)
                    )

                External url ->
                    ( model, Navigation.load url )

        UrlChanged url ->
            ( routeToPage url model, Cmd.none )

        EnteredPassword string ->
            case model.page of
                LoginForm _ ->
                    ( { model | page = LoginForm string }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SelectedParticipant string ->
            case model.page of
                LoginForm password ->
                    ( model
                    , Navigation.pushUrl model.navKey ("/wichteln_2018/" ++ string)
                    )

                _ ->
                    ( model, Cmd.none )

        SubmitLogin ->
            case model.page of
                LoginForm password ->
                    ( { model | page = Waiting }
                    , submitLogin model.self password
                    )

                _ ->
                    ( model, Cmd.none )

        LoginResponse (Ok success) ->
            case model.page of
                Waiting ->
                    ( { model
                        | page =
                            Participate.init success
                                |> Tuple.first
                                |> Result
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        LoginResponse (Err err) ->
            -- let
            --     _ =
            --         Debug.log "LoginResponse Error" err
            -- in
            ( { model | page = LoginError err }, Cmd.none )

        LoginAgain ->
            ( { model | page = LoginForm "" }, Cmd.none )

        ParticipateMsg msg_ ->
            case model.page of
                Result state ->
                    let
                        ( change, cmd ) =
                            Participate.update msg_ state
                    in
                    ( { model | page = Result change }
                    , Cmd.map ParticipateMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )


submitLogin : String -> String -> Cmd Msg
submitLogin self password =
    Http.post
        { url = "/wichteln_2018/api.php"
        , body =
            Http.multipartBody
                [ Http.stringPart "name" self
                , Http.stringPart "password" password
                ]
        , expect = Http.expectJson LoginResponse loginResponseDecoder
        }


loginResponseDecoder : Json.Decoder { self : String, target : String }
loginResponseDecoder =
    Json.map2 LoginSuccess
        (Json.field "name" Json.string)
        (Json.field "partner" Json.string)


type alias LoginSuccess =
    { self : String, target : String }



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "Wichteln"
    , body =
        case model.page of
            LoginForm password ->
                [ login model.self password model.participants ]

            Waiting ->
                [ div [ class "centered" ]
                    [ h1 [] [ text "Wichteln" ]
                    , p [] [ text "Am Laden" ]
                    ]
                ]

            LoginError err ->
                [ div [ class "centered" ]
                    [ h1 [] [ text "Passwort falsch." ]
                    , button [ class "button", onClick LoginAgain ]
                        [ text "Nochmal versuchen" ]
                    ]
                ]

            Result state ->
                [ Participate.view state
                    |> Html.map ParticipateMsg
                ]
    }


login : String -> String -> List String -> Html Msg
login self password participants =
    Html.form [ class "centered", onSubmit SubmitLogin ]
        [ h1 [] [ text "Wichteln" ]
        , p [] [ text "Damit keiner spicken kann, wen Du gezogen hast, musst Du ein Passwort vergeben." ]
        , p []
            [ text "Danach kannst Du Deinen Wichtel ziehen"
            , br [] []
            , text "Mit dem Passwort kannst Du dann jederzeit nochmal schauen, wen Du beschenken darfst."
            ]
        , div [ class "wide-row" ]
            [ select [ name "name", onInput SelectedParticipant ] <| List.map (person self) participants
            , input
                [ type_ "password"
                , maxlength 255
                , placeholder "Passwort"
                , required True
                , onInput EnteredPassword
                ]
                [ text password ]
            , input [ class "button", type_ "submit", value "Anmelden" ] []
            ]
        ]


person : String -> String -> Html msg
person self name =
    option [ value name, selected (self == name) ] [ text name ]



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = ClickedLink
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
