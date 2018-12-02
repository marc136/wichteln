module Page.Create exposing (allEmailsFilledIfNeeded, init, noGdprConfirmation, tooFewParticipants, update, view)

import Browser.Dom as Dom
import Date exposing (Date)
import Dev
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D exposing (Value)
import Json.Encode as E
import Page.Create.Constants as Constants
import Page.Create.Encoder as Encoder
import Page.Create.Message exposing (Msg(..))
import Page.Create.Model as Model exposing (Filter(..), Kind(..), Model, Participant, SettingsError(..))
import Page.Create.Sanitize as Sanitize
import Page.Create.Stage as Stage exposing (Stage)
import Task



---- MODEL ----


init : ( Model, Cmd Msg )
init =
    ( Model.default, Task.perform Today Date.today )
        |> Tuple.mapFirst (\_ -> test1)


test1 : Model
test1 =
    { today = Date.fromOrdinalDate 2018 123
    , stage = Stage.LastCheck
    , highestStage = Stage.LastCheck
    , kind = FixedList
    , filterFields = NameAndEmail
    , participants =
        [ { name = "1", email = "b@dev.xz" }
        , { name = "2", email = "" }
        , { name = "3", email = "" }
        , { name = "4", email = "d@a.com" }
        ]
    , mayStoreEmail = False
    , deleteAfter = 31
    , settingsErrors = []
    , lastResponse = Ok "leer"
    }



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Today today ->
            ( { model | today = today }, Cmd.none )

        GoTo stage ->
            ( goto stage model, Cmd.none )

        Pick kind ->
            ( { model | kind = kind }
                |> goto Stage.ChooseFilter
            , Cmd.none
            )

        PickFilter filter ->
            ( { model | filterFields = filter }
                |> goto Stage.EnterParticipants
            , focus <| participantId (List.length model.participants - 1)
            )

        AddParticipant ->
            ( { model
                | participants = model.participants ++ [ Model.newParticipant ]
              }
            , focus <| participantId (List.length model.participants)
            )

        ChangeParticipantName index string ->
            let
                changed =
                    set index (\p -> { p | name = string }) model.participants
            in
            ( { model | participants = changed }, Cmd.none )

        ChangeParticipantEmail index string ->
            ( { model
                | participants =
                    set index (\p -> { p | email = string }) model.participants
                , mayStoreEmail = False
              }
            , Cmd.none
            )

        ToggleMayStoreEmails ->
            ( { model | mayStoreEmail = not model.mayStoreEmail }, Cmd.none )

        DeleteAfter Nothing ->
            ( model, Cmd.none )

        DeleteAfter (Just days) ->
            ( { model | deleteAfter = days }, Cmd.none )

        Submit ->
            ( model
            , Http.post "/create"
                (Http.jsonBody (Encoder.encode model))
                D.value
                |> Http.send SubmitResponse
            )

        SubmitResponse (Err err) ->
            -- let
            --     _ =
            --         Debug.log "SubmitResponse Err" err
            -- in
            ( model, Cmd.none )

        SubmitResponse result ->
            result
                |> Result.map Dev.jsonToString
                |> (\r -> ( { model | lastResponse = r }, Cmd.none ))


goto : Stage -> Model -> Model
goto stage model =
    { model | stage = stage }
        |> increaseHighestStageIfNeeded stage
        |> trimParticipantsIfNeeded stage
        |> checkForSettingsErrors


trimParticipantsIfNeeded : Stage -> Model -> Model
trimParticipantsIfNeeded stage model =
    if stage == Stage.LastCheck then
        { model | participants = Sanitize.dropEmptyParticipants model }

    else
        model


increaseHighestStageIfNeeded : Stage -> Model -> Model
increaseHighestStageIfNeeded stage model =
    case Stage.compare stage model.highestStage of
        GT ->
            { model | highestStage = stage }

        _ ->
            model


focus : String -> Cmd Msg
focus id =
    Task.attempt (\_ -> NoOp) (Dom.focus id)


set : Int -> (a -> a) -> List a -> List a
set index fn =
    List.indexedMap
        (\i a ->
            if i == index then
                fn a

            else
                a
        )


checkForSettingsErrors : Model -> Model
checkForSettingsErrors model =
    { model | settingsErrors = checkSettingsErrors model }


checkSettingsErrors : Model -> List SettingsError
checkSettingsErrors model =
    [ tooFewParticipants model
    , allEmailsFilledIfNeeded model
    , noGdprConfirmation model
    ]
        |> List.filterMap identity


tooFewParticipants : Model -> Maybe SettingsError
tooFewParticipants model =
    if
        Sanitize.dropEmptyParticipants model
            |> List.length
            |> (>) Constants.minimumParticipants
    then
        Just TooFewParticipants

    else
        Nothing


allEmailsFilledIfNeeded : Model -> Maybe SettingsError
allEmailsFilledIfNeeded model =
    if model.filterFields /= NameAndEmail then
        Nothing

    else if
        Sanitize.dropEmptyParticipants model
            |> List.any (\p -> String.isEmpty p.email)
    then
        Just EmailsMissing

    else
        Nothing


noGdprConfirmation : Model -> Maybe SettingsError
noGdprConfirmation model =
    if model.filterFields == OnlyNames || model.mayStoreEmail then
        Nothing

    else
        Just MayNotStoreEmail



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "wichteln-create" ]
        [ div [ class "wrapper" ]
            [ header model
            , case model.stage of
                Stage.ChooseKind ->
                    chooseKind model

                Stage.ChooseFilter ->
                    chooseFilter model

                Stage.EnterParticipants ->
                    enterParticipants model.participants model.filterFields

                Stage.ConfirmDataProtection ->
                    confirm model

                Stage.LastCheck ->
                    if model.settingsErrors == [] then
                        lastCheck model

                    else
                        checkFailed model
            , button [ onClick Submit ] [ text "dev submit" ]
            , case model.lastResponse of
                Ok response ->
                    div []
                        [ h2 [] [ text "Last response: Ok" ]
                        , pre [] [ code [] [ text response ] ]
                        ]

                Err response ->
                    div []
                        [ h2 [] [ text "Last response: Error " ]
                        -- , pre [] [ code [] [ text (Debug.toString response) ] ] -- TODO
                        ]
            ]
        ]


header : Model -> Html Msg
header model =
    let
        event stage =
            if Stage.toInt model.highestStage - Stage.toInt stage >= -1 then
                GoTo stage

            else
                NoOp

        btn stage =
            li
                [ onClick <| event stage
                , classList
                    [ ( "not-visited", Stage.compare model.highestStage stage == LT )
                    , ( "current", model.stage == stage )
                    ]
                ]
                [ a [ href "#" ] [ text <| Stage.toString stage ] ]
    in
    div [ class "progress-dots" ]
        [ ul [ class "stages" ]
            [ btn Stage.ChooseKind
            , btn Stage.ChooseFilter
            , btn Stage.EnterParticipants
            , btn Stage.ConfirmDataProtection
            , btn Stage.LastCheck
            ]
        ]


chooseKind : Model -> Html Msg
chooseKind model =
    let
        maybeKind =
            if model.highestStage /= Stage.ChooseKind then
                Just model.kind

            else
                Nothing

        revisit =
            model.highestStage /= Stage.ChooseKind
    in
    div []
        [ h1 [] [ text "Schritt eins: Liste" ]
        , div []
            [ div
                [ class "half"
                , classList [ ( "selected", revisit && (model.kind == FixedList) ) ]
                , onClick (Pick FixedList)
                ]
                [ p [] [ text "Ich habe eine fertige Liste aller Teilnehmer" ] ]
            , div
                [ class "half"
                , classList [ ( "selected", revisit && (model.kind == InviteParticipants) ) ]
                , onClick (Pick InviteParticipants)
                ]
                [ p [] [ text "Jeder Teilnehmer soll zuerst noch bestätigen, ob er teilnehmen möchte." ]
                ]
            ]
        , if revisit then
            div [ class "gotoButtons" ]
                [ button
                    [ class "forward", onClick <| GoTo Stage.ChooseFilter ]
                    [ text "weiter" ]
                ]

          else
            text ""
        ]


chooseFilter : Model -> Html Msg
chooseFilter model =
    div []
        [ h1 [] [ text "Schritt zwei: Benachrichtigungen" ]
        , fieldFilter model.filterFields OnlyNames
        , fieldFilter model.filterFields NameOrEmail
        , fieldFilter model.filterFields NameAndEmail
        , div [ class "gotoButtons" ]
            [ button
                [ class "back", onClick <| GoTo Stage.ChooseKind ]
                [ text "zurück" ]
            , button
                [ class "forward", onClick <| GoTo Stage.EnterParticipants ]
                [ text "weiter" ]
            ]
        ]


fieldFilter : Filter -> Filter -> Html Msg
fieldFilter current this =
    let
        ( id_, caption ) =
            filterToString this
    in
    div []
        [ input
            [ type_ "radio"
            , name "filter"
            , value caption
            , checked (current == this)
            , id id_
            , onClick <| PickFilter this
            ]
            []
        , label [ for id_ ] [ text caption ]
        ]


filterToString : Filter -> ( String, String )
filterToString filter =
    case filter of
        OnlyNames ->
            ( "only-names"
            , "Ich werde alle Teilnehmer selbst benachrichtigen"
            )

        NameOrEmail ->
            ( "name-or-email"
            , "Willi und ich teilen uns die Arbeit"
            )

        NameAndEmail ->
            ( "name-and-email"
            , "Willi soll alle Teilnehmer benachrichtigen"
            )


enterParticipants : List Participant -> Filter -> Html Msg
enterParticipants participants filter =
    div []
        [ h1 [] [ text "Teilnehmer eingeben:" ]
        , ul [ class "participants enter" ]
            (List.indexedMap (enterParticipant filter) participants)
        , button [ onClick AddParticipant ] [ text "Teilnehmer hinzufügen" ]
        , hr [] []
        , div [ class "gotoButtons" ]
            [ button
                [ class "back", onClick <| GoTo Stage.ChooseFilter ]
                [ text "zurück" ]
            , button
                [ class "forward", onClick <| GoTo Stage.ConfirmDataProtection ]
                [ text "weiter" ]
            ]
        ]


enterParticipant : Filter -> Int -> Participant -> Html Msg
enterParticipant filter index participant =
    if filter == OnlyNames then
        li []
            [ input
                [ value participant.name
                , onInput (ChangeParticipantName index)
                , id <| participantId index
                ]
                []
            ]

    else
        let
            id_ =
                participantId index
        in
        li []
            [ label [ for id_ ] [ text "Name" ]
            , input
                [ id id_
                , value participant.name
                , onInput (ChangeParticipantName index)
                ]
                []
            , label [ for (id_ ++ "_email") ] [ text "Email" ]
            , input
                [ id (id_ ++ "_email")
                , value participant.email
                , onInput (ChangeParticipantEmail index)
                ]
                []
            ]


participantId : Int -> String
participantId index =
    "participant" ++ String.fromInt index


confirm : Model -> Html Msg
confirm model =
    div []
        [ h1 [] [ text "confirm TODO" ]
        , if model.filterFields /= OnlyNames then
            let
                id_ =
                    "confirm-gdpr"
            in
            div [ class "row" ]
                [ input
                    [ id id_
                    , type_ "checkbox"
                    , value "gdpr"
                    , onClick ToggleMayStoreEmails
                    , checked model.mayStoreEmail
                    ]
                    []
                , label [ for id_ ]
                    [ text "Ich habe die Einwilligung von allen Teilnehmern, ihre Email Adressen bei Willi zu speichern." ]
                ]

          else
            text ""
        , label [ for "delete-after" ] [ text "Daten löschen nach" ]
        , select [ id "delete-after", onInput (DeleteAfter << String.toInt) ]
            [ option [ value "14", selected (model.deleteAfter == 14) ]
                [ text "Zwei Wochen" ]
            , option [ value "31", selected (model.deleteAfter == 31) ]
                [ text "Einem Monat" ]
            , option [ value "93", selected (model.deleteAfter == 93) ]
                [ text "Drei Monaten" ]
            , option [ value "186", selected (model.deleteAfter == 186) ]
                [ text "Sechs Monaten" ]
            , option [ value "279", selected (model.deleteAfter == 279) ]
                [ text "Neun Monaten" ]
            ]
        , div [ class "gotoButtons" ]
            [ button
                [ class "back", onClick <| GoTo Stage.EnterParticipants ]
                [ text "zurück" ]
            , button
                [ class "forward", onClick <| GoTo Stage.LastCheck ]
                [ text "weiter" ]
            ]
        ]


checkFailed : Model -> Html Msg
checkFailed model =
    div []
        [ h1 [] [ text "checkFailed" ]
        , summary model
        , debug model
        ]


lastCheck : Model -> Html Msg
lastCheck model =
    div []
        [ h1 [] [ text "lastCheck" ]
        , summary model
        , if List.length model.settingsErrors == 0 then
            button [ onClick Submit ] [ text "Erstellen" ]

          else
            button [ disabled True ]
                [ text "Kann nicht gespeichert werden, da Fehler existieren" ]
        , debug model
        ]


summary : Model -> Html Msg
summary model =
    div []
        [ p [] [ text (summaryStart model) ]
        , if Sanitize.hasError TooFewParticipants model then
            problem Stage.EnterParticipants "Es müssen mindestens vier Teilnehmer eingetragen werden, damit nicht sofort klar ist, wer wen beschenkt."

          else
            text ""
        , if List.length model.participants < Constants.minimumParticipants then
            text ""

          else
            div [] (summaryContact model)
        , div [] (summaryDataProtection model)
        , div [] []
        ]


problem : Stage -> String -> Html Msg
problem stage msg =
    div [ class "error" ]
        [ text ("Fehler: " ++ msg)
        , button
            [ onClick <| GoTo stage ]
            [ text "Fehler beheben" ]
        ]


summaryStart : Model -> String
summaryStart model =
    let
        startDate =
            Sanitize.startOn model
    in
    case model.kind of
        FixedList ->
            let
                startOn =
                    case Date.diff Date.Days model.today startDate of
                        0 ->
                            "sofort"

                        1 ->
                            "morgen"

                        _ ->
                            "am " ++ formatDate startDate
            in
            "Die Wichtel werden " ++ startOn ++ " ausgelost."

        InviteParticipants ->
            let
                startOn =
                    case Date.diff Date.Days model.today startDate of
                        0 ->
                            "Heute"

                        1 ->
                            "Bis Morgen"

                        _ ->
                            "Bis " ++ formatDate startDate
            in
            startOn ++ " können die Wichtel zusagen, danach beginnt das Auslosen."


formatDate : Date -> String
formatDate =
    Date.format "dd.MM.y"


summaryContact : Model -> List (Html Msg)
summaryContact model =
    let
        participants : List Participant
        participants =
            Sanitize.dropEmptyParticipants model

        count list =
            String.fromInt (List.length list)
    in
    case model.filterFields of
        OnlyNames ->
            [ text <| count participants ++ " Wichtel dürfen teilnehmen." ]

        NameOrEmail ->
            let
                ( manual, automated ) =
                    List.partition (String.isEmpty << .email) participants

                row string =
                    p [ class "row" ] [ text string ]
            in
            [ row <| count manual ++ " Wichtel werden von dir benachrichtigt."
            , ul [] <|
                List.map (\{ name } -> li [] [ text name ]) manual
            , row <| count automated ++ " Wichtel werden von Willi benachrichtigt."
            , ul [] <|
                List.map (\{ email } -> li [] [ text email ]) automated
            ]

        NameAndEmail ->
            [ "Alle "
                ++ count participants
                ++ " Wichtel werden von Willi benachrichtigt."
                |> text
            , if Sanitize.hasError EmailsMissing model then
                problem Stage.EnterParticipants "Willi braucht von jedem Teilnehmer eine Email Adresse."

              else
                List.map (\{ email } -> li [] [ text email ]) participants
                    |> ul []
            ]


summaryDataProtection : Model -> List (Html Msg)
summaryDataProtection model =
    [ if Sanitize.hasError MayNotStoreEmail model then
        problem Stage.ConfirmDataProtection "Willi hat nicht das Recht, die Teilnehmer zu speichern."

      else
        p []
            [ "Willi wird alle Daten nach dem "
                ++ formatDate (Sanitize.deleteAfter model)
                ++ " löschen."
                |> text
            ]
    ]


debug model =
    div []
        [ h1 []
            [ text "errors: "
            , text <| String.fromInt <| List.length model.settingsErrors
            ]
        , button [ onClick (GoTo Stage.LastCheck) ] [ text "again" ]
        , pre [] [ code [] [ text <| Dev.jsonToString <| Encoder.encode model ] ]
        ]
