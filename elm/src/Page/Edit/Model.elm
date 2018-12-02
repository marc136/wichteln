module Page.Edit.Model exposing (Model, Participant)

import Date exposing (Date)
import Http
import Page.Create.Stage exposing (Stage(..))


type alias Participant =
    { name : String, id : String }


type alias Model =
    -- { today : Date
    { id : String
    , participants : List Participant
    , startOn : Date
    , deleteAfter : Date
    }
