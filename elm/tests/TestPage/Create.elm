module TestPage.Create exposing (checkSettingsErrors)

import Expect
import Page.Create as Page
import Page.Create.Model as Model exposing (Filter(..), Model, SettingsError(..))
import Page.Create.Stage as Stage exposing (Stage(..))
import Test exposing (..)


checkSettingsErrors : Test
checkSettingsErrors =
    describe "Check Settings"
        [ describe "Minimum number of participants" tooFewParticipants
        , describe "All email fields filled" allEmailsFilledIfNeeded
        , describe "Was data protection confirmed" noGdprConfirmation
        ]


tooFewParticipants : List Test
tooFewParticipants =
    [ ( { model | participants = [] }
      , Just TooFewParticipants
      )
    , ( { model | participants = [ noName, noMail, full, empty ] }
      , Just TooFewParticipants
      )
    , ( { model
            | filterFields = NameOrEmail
            , participants = [ noName, noMail, full, empty, noName ]
        }
      , Nothing
      )
    , ( { model
            | filterFields = OnlyNames
            , participants = [ noName, noMail, full, empty, noName ]
        }
      , Just TooFewParticipants
      )
    ]
        |> List.indexedMap (settingsErrors Page.tooFewParticipants)


allEmailsFilledIfNeeded : List Test
allEmailsFilledIfNeeded =
    let
        all =
            { model | filterFields = NameAndEmail }
    in
    [ ( { all | participants = [] }, Nothing )
    , ( { all | participants = [ noName ] }, Nothing )
    , ( { all | participants = [ full, noName ] }, Nothing )
    , ( { all | participants = [ noMail ] }
      , Just EmailsMissing
      )
    , ( { all | participants = [ noMail, noName ] }
      , Just EmailsMissing
      )
    ]
        |> List.indexedMap (settingsErrors Page.allEmailsFilledIfNeeded)


noGdprConfirmation : List Test
noGdprConfirmation =
    [ ( { model | filterFields = OnlyNames, mayStoreEmail = True }
      , Nothing
      )
    , ( { model | filterFields = OnlyNames, mayStoreEmail = False }
      , Nothing
      )
    , ( { model | filterFields = NameOrEmail, mayStoreEmail = True }
      , Nothing
      )
    , ( { model | filterFields = NameAndEmail, mayStoreEmail = True }
      , Nothing
      )
    , ( { model | filterFields = NameOrEmail, mayStoreEmail = False }
      , Just MayNotStoreEmail
      )
    , ( { model | filterFields = NameAndEmail, mayStoreEmail = False }
      , Just MayNotStoreEmail
      )
    ]
        |> List.indexedMap (settingsErrors Page.noGdprConfirmation)


settingsErrors : (model -> maybe) -> Int -> ( model, maybe ) -> Test
settingsErrors fn index ( input, expected ) =
    indexedTest index expected <|
        \_ ->
            Expect.equal expected (fn input)


indexedTest : Int -> a -> (() -> Expect.Expectation) -> Test
indexedTest index expected =
    [ "Test", String.fromInt index, "Should return", Debug.toString expected ]
        |> String.join " "
        |> test


type alias Participant =
    { name : String, email : String }


noName : Participant
noName =
    { name = "", email = "email" }


noMail : Participant
noMail =
    { name = "name", email = "" }


full : Participant
full =
    { name = "name", email = "mail" }


empty : Participant
empty =
    Participant "" ""


model : Model
model =
    Model.default
