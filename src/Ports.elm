port module Ports exposing (..)


port openFlagPopup : { url : String } -> Cmd msg


port addVote : ({ categoryId : Int } -> msg) -> Sub msg
