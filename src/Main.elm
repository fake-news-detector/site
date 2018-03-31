module Main exposing (..)

import AutoExpand as AutoExpand
import Data.Category as Category exposing (Category)
import Data.Votes as Votes exposing (PeopleVotes, RobotPredictions, VerifiedVote, VotesResponse)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import FlagLink exposing (Query(..), decodeQuery)
import Html exposing (Html)
import Html.Attributes
import Http exposing (encodeUri)
import Locale.Languages exposing (Language)
import Locale.Locale as Locale exposing (translate)
import Locale.Words exposing (LocaleKey(..))
import Markdown
import RemoteData exposing (..)
import Return
import Stylesheet exposing (..)


type alias Model =
    { uuid : String
    , query : String
    , autoexpand : AutoExpand.State
    , refreshUrlCounter : Int -- hack: http://package.elm-lang.org/packages/mdgriffith/style-elements/4.2.0/Element-Input#textKey
    , response : WebData { query : String, votes : VotesResponse }
    , language : Language
    , flagLink : FlagLink.Model
    }


type alias Flags =
    { languages : List String, uuid : String }


type Msg
    = Response String (WebData VotesResponse)
    | UpdateInput { textValue : String, state : AutoExpand.State }
    | Submit
    | UseExample
    | MsgForFlagLink FlagLink.Msg


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        language =
            Locale.fromCodeArray flags.languages
    in
    ( { uuid = flags.uuid
      , query = ""
      , autoexpand = AutoExpand.initState (autoExpandConfig language)
      , refreshUrlCounter = 0
      , response = NotAsked
      , language = language
      , flagLink = FlagLink.init
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Response query response ->
            ( { model
                | response = RemoteData.map (\votes -> { query = query, votes = votes }) response
                , flagLink = FlagLink.init
              }
            , Cmd.none
            )

        UpdateInput { state, textValue } ->
            if String.isEmpty textValue then
                ( { model
                    | autoexpand = AutoExpand.initState (autoExpandConfig model.language)
                    , query = textValue
                  }
                , Cmd.none
                )
            else
                ( { model | autoexpand = state, query = textValue }, Cmd.none )

        Submit ->
            case decodeQuery model.query of
                Url url ->
                    ( { model | response = RemoteData.Loading }
                    , Votes.getVotes url ""
                        |> RemoteData.sendRequest
                        |> Cmd.map (Response model.query)
                    )

                Content content ->
                    ( { model | response = RemoteData.Loading }
                    , Votes.getVotesByContent content
                        |> RemoteData.sendRequest
                        |> Cmd.map (Response model.query)
                    )

                Invalid ->
                    ( model, Cmd.none )

                Empty ->
                    ( model, Cmd.none )

        UseExample ->
            { model | refreshUrlCounter = model.refreshUrlCounter + 1 }
                |> update
                    (UpdateInput
                        { textValue =
                            "http://www.acritica.com/channels/cotidiano/news/droga-que-pode-causar-atitudes-canibais-e-apreendida-no-brasil"
                        , state = AutoExpand.initState (autoExpandConfig model.language)
                        }
                    )
                |> Tuple.first
                |> update Submit

        MsgForFlagLink msg ->
            FlagLink.update msg model.flagLink
                |> Return.map (\flagLink -> { model | flagLink = flagLink })
                |> Return.mapCmd MsgForFlagLink


view : Model -> Html Msg
view model =
    Element.layout stylesheet <|
        row General
            [ center, width (percent 100), padding 20 ]
            [ column NoStyle
                [ maxWidth (px 800) ]
                [ wrappedRow NoStyle
                    [ paddingBottom 20, paddingTop 120, spread ]
                    [ h1 Title [] (text <| translate model.language FakeNewsDetector)
                    , row NoStyle
                        [ spacing 10 ]
                        [ link "https://chrome.google.com/webstore/detail/fake-news-detector/alomdfnfpbaagehmdokilpbjcjhacabk" <|
                            image NoStyle
                                [ height (px 48) ]
                                { src = "static/add-to-chrome.png"
                                , caption = translate model.language AddToChrome
                                }
                        , link "https://addons.mozilla.org/en-US/firefox/addon/fakenews-detector/" <|
                            image NoStyle
                                [ height (px 48) ]
                                { src = "static/add-to-firefox.png"
                                , caption = translate model.language AddToFirefox
                                }
                        ]
                    ]
                , urlToCheck model
                , explanation model
                ]
            ]


urlToCheck : Model -> Element Classes variation Msg
urlToCheck model =
    column NoStyle
        [ minHeight (px 200), spacing 10, paddingBottom 20 ]
        [ node "form"
            (row NoStyle
                [ onSubmit Submit ]
                [ row NoStyle
                    [ width fill ]
                    [ html <| AutoExpand.view (autoExpandConfig model.language) model.autoexpand model.query ]
                , button BlueButton [ width (percent 20) ] (text <| translate model.language Check)
                ]
            )
        , flagButtonAndVotes model
        ]


autoExpandConfig : Language -> AutoExpand.Config Msg
autoExpandConfig language =
    AutoExpand.config
        { onInput = UpdateInput
        , padding = 12
        , lineHeight = 21
        , minRows = 1
        , maxRows = 4
        }
        |> AutoExpand.withPlaceholder (translate language PasteLink)
        |> AutoExpand.withStyles
            [ ( "width", "100%" )
            , ( "resize", "none" )
            , ( "border", "1px solid rgb(200,200,200)" )
            , ( "font-size", "100%" )
            , ( "font", "inherit" )
            ]


flagButtonAndVotes : Model -> Element Classes variation Msg
flagButtonAndVotes model =
    let
        translate =
            Locale.translate model.language
    in
    column NoStyle
        [ spacing 20 ]
        [ when (decodeQuery model.query == Invalid)
            (paragraph NoStyle [] [ el General [ padding 5 ] (text <| translate InvalidQueryError) ])
        , el General
            [ spacing 5, minWidth (px 130) ]
            (case model.response of
                Success { query, votes } ->
                    viewVotes model query votes

                Failure _ ->
                    el NoStyle [ padding 6 ] (text <| translate LoadingError)

                RemoteData.Loading ->
                    text <| translate Locale.Words.Loading

                _ ->
                    empty
            )
        ]


viewVotes : Model -> String -> VotesResponse -> Element Classes variation Msg
viewVotes model query votes =
    let
        peopleVotes =
            Votes.joinClickbaitCategory votes.people

        viewPeopleVote vote =
            viewVote model (Category.toEmoji vote.category) (toString vote.count) vote.category ""
    in
    column NoStyle
        [ spacing 30 ]
        [ wrappedRow NoStyle
            [ spacing 20 ]
            [ viewRobotBestGuess model votes.domain votes.robot
            , if List.length peopleVotes > 0 then
                column NoStyle [ spacing 5 ] ([ bold <| translate model.language PeoplesOpinion ] ++ List.map viewPeopleVote peopleVotes)
              else
                empty
            , if List.length peopleVotes == 0 && Votes.predictionsToText votes.robot == [] && votes.domain == Nothing then
                nothingWrongExample model
              else
                empty
            ]
        , Element.map MsgForFlagLink (FlagLink.flagLink model.uuid query model.language model.flagLink)
        , when (List.length votes.keywords > 0)
            (viewSearchResults model votes)
        ]


viewSearchResults : Model -> VotesResponse -> Element Classes variation msg
viewSearchResults model votes =
    column NoStyle
        [ spacing 10 ]
        [ bold <| translate model.language CheckYourself
        , paragraph NoStyle [] [ text <| translate model.language WeDidAGoogleSearch ]
        , el NoStyle
            []
            (Element.html
                (Html.iframe
                    [ Html.Attributes.src ("static/searchResults.html?q=" ++ encodeUri (String.join " " votes.keywords))
                    , Html.Attributes.attribute "frameBorder" "0"
                    , Html.Attributes.attribute "height" "300px"
                    , Html.Attributes.attribute "width" "100%"
                    , Html.Attributes.attribute "onload" "resizeIframe(this)"
                    ]
                    []
                )
            )
        ]


viewRobotBestGuess : Model -> Maybe VerifiedVote -> RobotPredictions -> Element Classes variation Msg
viewRobotBestGuess model verifiedVote robotVotes =
    let
        robotPredictions =
            Votes.predictionsToText robotVotes

        viewRobotVote ( chanceText, category ) =
            viewVote model "\x1F916" (Locale.translate model.language chanceText) category ""

        renderPredictions items =
            column NoStyle
                [ spacing 5 ]
                ([ bold <| translate model.language RobinhosOpinion ] ++ items)
    in
    case ( verifiedVote, List.head robotPredictions ) of
        ( Just vote, _ ) ->
            renderPredictions [ viewVerifiedVote model vote ]

        ( Nothing, Just _ ) ->
            renderPredictions (List.map viewRobotVote robotPredictions)

        _ ->
            empty


nothingWrongExample : Model -> Element Classes variation Msg
nothingWrongExample model =
    paragraph NoStyle
        []
        [ text <| translate model.language NothingWrongExample
        , el NoStyle [ onClick UseExample ] (link "javascript:" (underline <| translate model.language ClickHere))
        ]


viewVote : Model -> String -> String -> Category -> String -> Element Classes variation msg
viewVote model icon preText category postText =
    row NoStyle
        [ padding 6, spacing 5, height (px 32) ]
        [ el VoteEmoji [ moveUp 4 ] (text icon)
        , text preText
        , text <| String.toLower <| translate model.language (Category.toName category)
        , text postText
        ]


viewVerifiedVote : Model -> VerifiedVote -> Element Classes variation msg
viewVerifiedVote model vote =
    viewVote model (Category.toEmoji vote.category) "" vote.category (translate model.language Verified)


explanation : Model -> Element Classes variation msg
explanation model =
    html <| Markdown.toHtml [] (Locale.translate model.language Explanation)


staticView : String -> Html Msg
staticView lang =
    view (Tuple.first <| init { languages = [ lang ], uuid = "" })


staticViewPt : Html Msg
staticViewPt =
    staticView "pt"


staticViewEn : Html Msg
staticViewEn =
    staticView "en"


staticViewEs : Html Msg
staticViewEs =
    staticView "es"
