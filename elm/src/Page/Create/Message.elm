module Page.Create.Message exposing (Msg(..))

import Date exposing (Date)
import Http
import Json.Decode exposing (Value)
import Page.Create.Model exposing (..)
import Page.Create.Stage exposing (Stage(..))


type Msg
    = NoOp
    | Today Date
    | Pick Kind
    | PickFilter Filter
    | AddParticipant
    | ChangeParticipantName Int String
    | ChangeParticipantEmail Int String
    | GoTo Stage
    | ToggleMayStoreEmails
    | DeleteAfter (Maybe Int)
    | Submit
    | SubmitResponse (Result Http.Error Value)
