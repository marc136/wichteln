module Page.Edit exposing (date, init, model, participant, splitDate, view)

import Date exposing (Date)
import Html exposing (Html)
import Json.Decode as Json
import Page.Edit.Message exposing (Msg(..))
import Page.Edit.Model exposing (Model, Participant)
import Page.Edit.View as View


init : Json.Value -> Result Json.Error Model
init =
    Json.decodeValue model


model : Json.Decoder Model
model =
    Json.map4 Model
        (Json.field "id" Json.string)
        (Json.field "participants" (Json.list participant))
        (Json.field "startOn" date)
        (Json.field "deleteAfter" date)


participant : Json.Decoder Participant
participant =
    Json.map2 Participant
        (Json.field "name" Json.string)
        (Json.field "id" Json.string)


date : Json.Decoder Date
date =
    Json.string |> Json.andThen splitDate


splitDate : String -> Json.Decoder Date
splitDate string =
    case Date.fromIsoString string of
        Ok date_ ->
            Json.succeed date_

        Err err ->
            Json.fail err


view : Model -> Html Msg
view =
    View.view
