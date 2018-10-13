module Page.Create.Sanitize exposing (deleteAfter, dropEmptyParticipants, emptyParticipant, hasError, startOn)

import Date exposing (Date)
import Page.Create.Model as Model exposing (Filter(..), Model, Participant, SettingsError)


dropEmptyParticipants : Model -> List Model.Participant
dropEmptyParticipants model =
    List.filter
        (not << emptyParticipant model.filterFields)
        model.participants


emptyParticipant : Filter -> Participant -> Bool
emptyParticipant filter { name, email } =
    case filter of
        OnlyNames ->
            String.isEmpty name

        NameOrEmail ->
            String.isEmpty name && String.isEmpty email

        NameAndEmail ->
            String.isEmpty name && String.isEmpty email


deleteAfter : Model -> Date
deleteAfter model =
    Date.add Date.Days model.deleteAfter model.today


startOn : Model -> Date
startOn model =
    Date.add Date.Days 0 model.today


hasError : SettingsError -> Model -> Bool
hasError error model =
    List.member error model.settingsErrors
