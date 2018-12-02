module Participate.Model exposing (Event, Model(..))


type Model
    = EnterPassword String
    | ShowResult Event


type alias Event =
    { self : String
    , target : String
    , visible : Bool
    , touch : Maybe ( Float, Float )
    }
