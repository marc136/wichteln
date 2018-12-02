module Page.Participate.Model exposing (Model(..), Event)


type Model
    = EnterPassword String
    | ShowResult Event

type alias Event =
    { self : String
    , target : String
    , visible : Bool
    , touch: Maybe (Float, Float)
    }
