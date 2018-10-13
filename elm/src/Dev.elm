module Dev exposing (jsonToString)

import Json.Encode as E exposing (Value)
import Json.Print


jsonToString : Value -> String
jsonToString json =
    case Json.Print.prettyValue { indent = 2, columns = 80 } json of
        Ok result ->
            result

        Err reason ->
            reason
