module Page.Create.Encoder exposing (encode)

import Date exposing (Date)
import Json.Encode as E exposing (Value)
import Page.Create.Model as Create exposing (Model)
import Page.Create.Sanitize as Sanitize


encode : Model -> Value
encode model =
    [ ( "kind", E.string <| kindToJson model.kind )
    , ( "participants", encodeParticipants model )
    , ( "mayStoreEmails", E.bool model.mayStoreEmail )
    , ( "deleteAfter", dateToJson <| Sanitize.deleteAfter model )
    , ( "startOn", dateToJson <| Sanitize.startOn model )
    ]
        |> E.object


dateToJson : Date -> Value
dateToJson =
    E.string << Date.toIsoString


kindToJson : Create.Kind -> String
kindToJson kind =
    case kind of
        Create.FixedList ->
            "fixedList"

        Create.InviteParticipants ->
            "inviteParticipants"


encodeParticipants : Model -> Value
encodeParticipants model =
    Sanitize.dropEmptyParticipants model
        |> clearEmailsIfNeeded model.mayStoreEmail
        |> E.list participantToJson


clearEmailsIfNeeded : Bool -> List Create.Participant -> List Create.Participant
clearEmailsIfNeeded keepEmails list =
    if keepEmails then
        list

    else
        List.map (\p -> { p | email = "" }) list


participantToJson : { name : String, email : String } -> Value
participantToJson participant =
    E.object
        [ ( "name", E.string participant.name )
        , ( "email", E.string participant.email )
        ]
