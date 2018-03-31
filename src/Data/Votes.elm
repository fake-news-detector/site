module Data.Votes exposing (..)

import Data.Category as Category exposing (..)
import Http exposing (encodeUri)
import Json.Decode exposing (Decoder, bool, float, int, list, nullable, string)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode


type alias PeopleVotes =
    { content : List PeopleContentVote
    , title : PeopleTitleVotes
    }


type alias PeopleContentVote =
    { category : Category, count : Int }


type alias PeopleTitleVotes =
    { clickbait : Bool, count : Int }


type alias RobotPredictions =
    { fake_news : Float, extremely_biased : Float, clickbait : Float }


type alias VerifiedVote =
    { category : Category }


type alias VotesResponse =
    { domain : Maybe VerifiedVote
    , robot : RobotPredictions
    , people : PeopleVotes
    , keywords : List String
    }


type YesNoIdk
    = Yes
    | No
    | DontKnow


type alias NewVote =
    { uuid : String
    , url : String
    , title : String
    , category : Category
    , clickbaitTitle : YesNoIdk
    }


encodeYesNoIdk : YesNoIdk -> Json.Encode.Value
encodeYesNoIdk val =
    case val of
        Yes ->
            Json.Encode.bool True

        No ->
            Json.Encode.bool False

        DontKnow ->
            Json.Encode.null


decodeVotesResponse : Decoder VotesResponse
decodeVotesResponse =
    let
        decodeCategory =
            required "category_id" (Json.Decode.map Category.fromId int)

        decodeDomainCategory =
            decode VerifiedVote
                |> decodeCategory

        decodeRobotPredictions =
            decode RobotPredictions
                |> required "fake_news" float
                |> required "extremely_biased" float
                |> required "clickbait" float

        decodeContentPeopleVote =
            decode PeopleContentVote
                |> decodeCategory
                |> required "count" int

        decodePeopleTitleVotes =
            decode PeopleTitleVotes
                |> required "clickbait" bool
                |> required "count" int

        decodePeopleVotes =
            decode PeopleVotes
                |> required "content" (list decodeContentPeopleVote)
                |> required "title" decodePeopleTitleVotes
    in
    decode VotesResponse
        |> required "domain" (nullable decodeDomainCategory)
        |> required "robot" decodeRobotPredictions
        |> required "people" decodePeopleVotes
        |> required "keywords" (list string)


apiUrl : String
apiUrl =
    "https://api.fakenewsdetector.org"


getVotes : String -> String -> Http.Request VotesResponse
getVotes url title =
    Http.get (apiUrl ++ "/votes?url=" ++ encodeUri url ++ "&title=" ++ encodeUri title) decodeVotesResponse


getVotesByContent : String -> Http.Request VotesResponse
getVotesByContent content =
    Http.get (apiUrl ++ "/votes_by_content?content=" ++ encodeUri content) decodeVotesResponse


encodeNewVote : NewVote -> Json.Encode.Value
encodeNewVote { uuid, url, title, category, clickbaitTitle } =
    Json.Encode.object
        [ ( "uuid", Json.Encode.string uuid )
        , ( "url", Json.Encode.string url )
        , ( "title", Json.Encode.string title )
        , ( "category_id", Json.Encode.int (Category.toId category) )
        , ( "clickbait_title", encodeYesNoIdk clickbaitTitle )
        ]


postVote : NewVote -> Http.Request ()
postVote newVote =
    Http.post (apiUrl ++ "/vote")
        (Http.jsonBody (encodeNewVote newVote))
        (Json.Decode.succeed ())


encodeNewVoteByContent : String -> String -> Category -> Json.Encode.Value
encodeNewVoteByContent uuid content category =
    Json.Encode.object
        [ ( "uuid", Json.Encode.string uuid )
        , ( "content", Json.Encode.string content )
        , ( "category_id", Json.Encode.int (Category.toId category) )
        ]


postVoteByContent : String -> String -> Category -> Http.Request ()
postVoteByContent uuid content category =
    Http.post (apiUrl ++ "/vote_by_content")
        (Http.jsonBody (encodeNewVoteByContent uuid content category))
        (Json.Decode.succeed ())


bestRobotGuess : RobotPredictions -> Maybe ( Category, Int )
bestRobotGuess robotVotes =
    [ ( FakeNews, robotVotes.fake_news )
    , ( ExtremelyBiased, robotVotes.extremely_biased )
    , ( Clickbait, robotVotes.clickbait )
    ]
        |> List.filter (\prediction -> Tuple.second prediction > 0.5)
        |> List.sortBy Tuple.second
        |> List.map (\( category, chance ) -> ( category, round (chance * 100) ))
        |> List.head
