module Page.Edit.View exposing (view)

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode as Json
import Page.Edit.Message exposing (Msg(..))
import Page.Edit.Model exposing (Model, Participant)



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "hi" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "Name" ]
                    , th [] [ text "Link" ]
                    ]
                ]
            , tbody [] <| List.map (participant model.id) model.participants
            ]
        ]


participant : String -> Participant -> Html Msg
participant base self =
    tr []
        [ td [] [ text self.name ]
        , td [] [ text self.id ]
        ]
