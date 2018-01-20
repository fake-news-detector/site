module Data.Hoaxes exposing (..)

import Data.Category as Category exposing (..)
import Http exposing (encodeUri)
import Json.Decode exposing (Decoder, float, int, list, nullable)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode
import List.Extra


type alias HoaxRobotVote =
    { category : Category, chance : Float }


type alias HoaxCheckResponse =
    List HoaxRobotVote


decodeHoaxCheckResponse : Decoder HoaxCheckResponse
decodeHoaxCheckResponse =
    let
        decodeCategory =
            required "category_id" (Json.Decode.map Category.fromId int)

        decodeRobotVote =
            decode HoaxRobotVote
                |> decodeCategory
                |> required "chance" float
    in
    list decodeRobotVote


getHoaxCheck : String -> Http.Request HoaxCheckResponse
getHoaxCheck content =
    Http.get ("https://api.fakenewsdetector.org/hoax/check?content=" ++ encodeUri content) decodeHoaxCheckResponse


encodeNewHoax : String -> String -> Json.Encode.Value
encodeNewHoax uuid content =
    Json.Encode.object
        [ ( "uuid", Json.Encode.string uuid )
        , ( "content", Json.Encode.string content )
        ]


postHoax : String -> String -> Http.Request ()
postHoax uuid content =
    Http.post "https://api.fakenewsdetector.org/hoax"
        (Http.jsonBody (encodeNewHoax uuid content))
        (Json.Decode.succeed ())


bestRobotGuess : List HoaxRobotVote -> Maybe ( Category, Int )
bestRobotGuess robotHoaxes =
    List.Extra.maximumBy (\robotVote -> robotVote.chance) robotHoaxes
        |> Maybe.map (\vote -> ( vote.category, round (vote.chance * 100) ))
