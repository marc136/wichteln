module Page.Create exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)



---- MODEL ----


type alias Model =
    { stage : Stage
    , kind : Kind
    , filterFields : Filter
    , participants : List Participant
    }


type Stage
    = ChooseKind (Maybe Kind)
    | ChooseFilter (Maybe Filter)
    | EnterParticipants


type Kind
    = FixedList
    | InviteParticipants


type Filter
    = OnlyNames
    | NamesAndEmail
    | All


type alias Participant =
    { name : String
    , email : String
    }


newParticipant : Participant
newParticipant =
    { name = ""
    , email = ""
    }


emptyParticipant : Filter -> Participant -> Bool
emptyParticipant filter { name, email } =
    case filter of
        OnlyNames ->
            String.isEmpty name

        NamesAndEmail ->
            String.isEmpty name && String.isEmpty email

        All ->
            String.isEmpty name && String.isEmpty email


init : ( Model, Cmd Msg )
init =
    ( default, Cmd.none )


default : Model
default =
    { stage = ChooseKind Nothing
    , kind = FixedList
    , filterFields = NamesAndEmail
    , participants = [ newParticipant ]
    }



---- UPDATE ----


type Msg
    = NoOp
    | Pick Kind
    | PickFilter Filter
    | AddParticipant
    | ChangeParticipantName Int String
    | ChangeParticipantEmail Int String
    | CheckParticipants


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Pick kind ->
            ( { model
                | kind = kind
                , stage =
                    if model.stage /= EnterParticipants then
                        ChooseFilter Nothing

                    else
                        model.stage
              }
            , Cmd.none
            )

        PickFilter filter ->
            ( { model | filterFields = filter, stage = EnterParticipants }
            , Cmd.none
            )

        AddParticipant ->
            ( { model | participants = model.participants ++ [ newParticipant ] }
            , Cmd.none
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
              }
            , Cmd.none
            )

        CheckParticipants ->
            -- TODO
            -- ( { model  })
            ( model, Cmd.none )


set : Int -> (a -> a) -> List a -> List a
set index fn =
    List.indexedMap
        (\i a ->
            if i == index then
                fn a

            else
                a
        )



-- checkParticipants : Model ->
-- checkParticipants { filterFields, participants } =
---- VIEW ----


view : Model -> Html Msg
view model =
    case model.stage of
        ChooseKind maybeKind ->
            chooseKind maybeKind

        ChooseFilter maybeFilter ->
            chooseFilter maybeFilter

        EnterParticipants ->
            -- div []
            --     [ h1 [] [ text "Your Elm App is working!" ]
            --     , a [ href "/neu" ] [ text "/neu" ]
            --     ]
            enterParticipants model.participants model.filterFields


chooseKind : Maybe Kind -> Html Msg
chooseKind maybeKind =
    div []
        [ h1 [] [ text "Schritt eins: Liste" ]
        , div []
            [ div [ class "half", onClick (Pick FixedList) ]
                [ p [] [ text "Ich habe eine fertige Liste aller Teilnehmer" ] ]
            , div [ class "half", onClick (Pick InviteParticipants) ]
                [ p [] [ text "Jeder Teilnehmer soll zuerst noch bestätigen, ob er teilnehmen möchte." ]
                ]
            ]
        ]


chooseFilter : Maybe Filter -> Html Msg
chooseFilter maybeFilter =
    div []
        [ h1 [] [ text "Schritt zwei: Benachrichtigungen" ]
        , fieldFilter (Maybe.withDefault All maybeFilter) OnlyNames
        , fieldFilter (Maybe.withDefault OnlyNames maybeFilter) All
        , fieldFilter (Maybe.withDefault All maybeFilter) NamesAndEmail
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

        NamesAndEmail ->
            ( "names-and-email"
            , "Willi soll alle Teilnehmer benachrichtigen"
            )

        All ->
            ( "all"
            , "Willi und ich teilen uns die Arbeit"
            )


enterParticipants : List Participant -> Filter -> Html Msg
enterParticipants participants filter =
    div []
        [ h1 [] [ text "Teilnehmer eingeben:" ]
        , ul [] (List.indexedMap (enterParticipant filter) participants)
        , button [ onClick AddParticipant ] [ text "Teilnehmer hinzufügen" ]
        , hr [] []
        , button [ onClick CheckParticipants ] [ text "weiter" ]
        ]


enterParticipant : Filter -> Int -> Participant -> Html Msg
enterParticipant filter index participant =
    if filter == OnlyNames then
        li []
            [ input
                [ value participant.name
                , onInput (ChangeParticipantName index)
                ]
                []
            ]

    else
        let
            id_ =
                participantId index
        in
        li []
            [ label [ for (id_ ++ "_name") ] [ text "Name" ]
            , input
                [ id (id_ ++ "_name")
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
