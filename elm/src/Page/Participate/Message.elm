module Page.Participate.Message exposing (Msg(..))


type Msg
    = NoOp
    | Toggle
    | StartTouch (Maybe (Float, Float))
    | MoveTouch (Maybe (Float, Float))
    | EndTouch