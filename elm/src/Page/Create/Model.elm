module Page.Create.Model exposing (Filter(..), Kind(..), Model, Participant, SettingsError(..), default, newParticipant)

import Date exposing (Date)
import Http
import Page.Create.Stage exposing (Stage(..))


type alias Model =
    { today : Date
    , stage : Stage
    , highestStage : Stage
    , kind : Kind
    , filterFields : Filter
    , participants : List Participant
    , mayStoreEmail : Bool
    , deleteAfter : Int
    , settingsErrors : List SettingsError
    , lastResponse : Result Http.Error String
    }


type SettingsError
    = TooFewParticipants
    | EmailsMissing
    | MayNotStoreEmail


type Kind
    = FixedList
    | InviteParticipants


type Filter
    = OnlyNames
    | NameOrEmail -- and/or (not XOR)
    | NameAndEmail


type alias Participant =
    { name : String
    , email : String
    }


default : Model
default =
    { today = Date.fromOrdinalDate 2018 123
    , stage = ChooseKind
    , highestStage = ChooseKind
    , kind = FixedList
    , filterFields = OnlyNames
    , participants =
        [ newParticipant, newParticipant, newParticipant, newParticipant ]
    , mayStoreEmail = False
    , deleteAfter = 31
    , settingsErrors = []
    , lastResponse = Ok "leer"
    }


newParticipant : Participant
newParticipant =
    { name = ""
    , email = ""
    }
