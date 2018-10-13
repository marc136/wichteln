module Page.Create.Stage exposing (Stage(..), compare, toInt, toString)


type Stage
    = ChooseKind
    | ChooseFilter
    | EnterParticipants
    | ConfirmDataProtection
    | LastCheck


compare : Stage -> Stage -> Order
compare a b =
    Basics.compare (toInt a) (toInt b)


toInt : Stage -> Int
toInt stage =
    case stage of
        ChooseKind ->
            1

        ChooseFilter ->
            2

        EnterParticipants ->
            3

        ConfirmDataProtection ->
            4

        LastCheck ->
            5


toString : Stage -> String
toString stage =
    case stage of
        ChooseKind ->
            "Anfang"

        ChooseFilter ->
            "Benachrichtigungen"

        EnterParticipants ->
            "Teilnehmer"

        ConfirmDataProtection ->
            "Datenschutz"

        LastCheck ->
            "Überprüfen"
