module Main exposing (..)

import Element exposing (..)
import Html
import Style exposing (..)


main : Html.Html msg
main =
    view


type Classes
    = NoStyle


stylesheet : Style.StyleSheet Classes variation
stylesheet =
    styleSheet []


view : Html.Html msg
view =
    Element.layout stylesheet (text "sip")


staticView : Html.Html msg
staticView =
    view
