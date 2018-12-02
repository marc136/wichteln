port module Participate exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Json.Decode as JD
import Json.Encode as JE
import Participate.Lamp as Lamp
import Participate.Message exposing (Msg(..))
import Participate.Model exposing (Event, Model(..))


init : { self : String, target : String } -> ( Model, Cmd Msg )
init { self, target } =
    ( ShowResult
        { self = self
        , target = target
        , visible = False
        , touch = Nothing
        }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( Toggle, ShowResult event ) ->
            ( ShowResult { event | visible = not event.visible }
            , playLampClick
            )

        ( StartTouch maybeTouch, ShowResult event ) ->
            ( ShowResult { event | touch = maybeTouch }, Cmd.none )

        ( MoveTouch (Just ( y, _ )), ShowResult event ) ->
            ( ShowResult
                { event
                    | touch =
                        Maybe.map (\( start, _ ) -> ( start, y )) event.touch
                }
            , Cmd.none
            )

        ( EndTouch, ShowResult event ) ->
            case event.touch of
                Just ( start, last ) ->
                    if last > start then
                        ( ShowResult
                            { event
                                | touch = Nothing
                                , visible = not event.visible
                            }
                        , playLampClick
                        )

                    else
                        noTouch event

                Nothing ->
                    noTouch event

        _ ->
            ( model, Cmd.none )


noTouch event =
    ( ShowResult { event | touch = Nothing }, Cmd.none )


playLampClick : Cmd msg
playLampClick =
    JE.object [ ( "play", JE.string "lamp-click" ) ]
        |> participate


view : Model -> Html Msg
view model =
    case model of
        EnterPassword name ->
            -- Debug.todo "view EnterPassword"
            text "todo"

        ShowResult event ->
            showResult event


showResult : Event -> Html Msg
showResult { self, target, visible, touch } =
    div
        [ class "wrapper lamp"
        , classList [ ( "active", visible ), ( "pulling", touch /= Nothing ) ]
        , Touch.onStart (StartTouch << getTouch)
        , Touch.onMove (MoveTouch << getTouch)
        , Touch.onEnd (\_ -> EndTouch)
        , Touch.onCancel (\_ -> NoOp)
        ]
        [ Lamp.treesLeft
        , Lamp.treesRight
        , div [ class "shine" ] []
        , p [ class "result top" ] [ text "Du darfst" ]
        , Lamp.lamp target Toggle
        , p [ class "result bottom" ] [ text "beschenken!" ]
        ]


getTouch : { e | touches : List Touch.Touch } -> Maybe ( Float, Float )
getTouch { touches } =
    List.head touches
        |> Maybe.map .clientPos
        |> Maybe.map (\( x, y ) -> ( y, y ))


port participate : JE.Value -> Cmd msg
