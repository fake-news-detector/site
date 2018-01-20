module Main exposing (..)

import Data.Category as Category exposing (Category)
import Data.Hoaxes as Hoaxes exposing (HoaxCheckResponse, HoaxRobotVote)
import Data.Votes as Votes exposing (PeopleVote, RobotVote, VerifiedVote, VotesResponse)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import FlagLink
import Html exposing (Html)
import Locale.Languages exposing (Language)
import Locale.Locale as Locale exposing (translate)
import Locale.Words exposing (LocaleKey(..))
import Markdown
import RemoteData exposing (..)
import Return
import Stylesheet exposing (..)
import Vendor.AutoExpand as AutoExpand


type alias Model =
    { uuid : String
    , query : String
    , autoexpand : AutoExpand.State
    , refreshUrlCounter : Int -- hack: http://package.elm-lang.org/packages/mdgriffith/style-elements/4.2.0/Element-Input#textKey
    , response : WebData QueryResponse
    , language : Language
    , flagLink : FlagLink.Model
    }


type QueryResponse
    = QueryLinkResponse VotesResponse
    | QueryContentResponse HoaxCheckResponse


type alias Flags =
    { languages : List String, uuid : String }


type Msg
    = Response (WebData QueryResponse)
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
        Response response ->
            ( { model | response = response, flagLink = FlagLink.init }, Cmd.none )

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
                        |> Cmd.map (Response << RemoteData.map QueryLinkResponse)
                    )

                Content content ->
                    ( { model | response = RemoteData.Loading }
                    , Hoaxes.getHoaxCheck content
                        |> RemoteData.sendRequest
                        |> Cmd.map (Response << RemoteData.map QueryContentResponse)
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


type Query
    = Url String
    | Content String
    | Invalid
    | Empty


decodeQuery : String -> Query
decodeQuery query =
    if String.isEmpty query then
        Empty
    else if String.startsWith "http" query then
        Url query
    else if String.length query >= 20 then
        Content query
    else
        Invalid


flagButtonAndVotes : Model -> Element Classes variation Msg
flagButtonAndVotes model =
    let
        translate =
            Locale.translate model.language

        viewVerifiedVote vote =
            viewVote model (Category.toEmoji vote.category) "" vote.category (translate Verified)
    in
    case decodeQuery model.query of
        Invalid ->
            paragraph NoStyle [] [ el General [ padding 5 ] (text <| translate InvalidQueryError) ]

        _ ->
            el General
                [ spacing 5, minWidth (px 130) ]
                (case model.response of
                    Success response ->
                        case response of
                            QueryLinkResponse votes ->
                                case votes.verified of
                                    Just vote ->
                                        viewVerifiedVote vote

                                    Nothing ->
                                        viewVotes model votes

                            QueryContentResponse hoaxCheck ->
                                text "Not implemented"

                    Failure _ ->
                        el VoteCountItem [ padding 6 ] (text <| translate LoadingError)

                    RemoteData.Loading ->
                        text <| translate Locale.Words.Loading

                    _ ->
                        empty
                )


viewVotes : Model -> VotesResponse -> Element Classes variation Msg
viewVotes model votes =
    let
        viewRobotVote ( category, chance ) =
            viewVote model "\x1F916" (toString chance ++ "%") category ""

        viewPeopleVote vote =
            viewVote model (Category.toEmoji vote.category) (toString vote.count) vote.category ""

        translate_ =
            translate model.language
    in
    column NoStyle
        [ spacing 30 ]
        [ wrappedRow NoStyle
            [ spacing 20 ]
            [ case Votes.bestRobotGuess votes.robot of
                Just bestGuess ->
                    column NoStyle
                        [ spacing 5 ]
                        [ bold <| translate_ RobinhosOpinion
                        , viewRobotVote bestGuess
                        ]

                Nothing ->
                    empty
            , if List.length votes.people > 0 then
                column NoStyle [ spacing 5 ] ([ bold <| translate_ PeoplesOpinion ] ++ List.map viewPeopleVote votes.people)
              else
                empty
            , if List.length votes.people == 0 && Votes.bestRobotGuess votes.robot == Nothing then
                paragraph NoStyle
                    []
                    [ text <| translate_ NothingWrongExample
                    , el NoStyle [ onClick UseExample ] (link "javascript:" (underline <| translate_ ClickHere))
                    ]
              else
                empty
            ]
        , Element.map MsgForFlagLink (FlagLink.flagLink model.uuid model.query model.language model.flagLink)
        ]


viewVote : Model -> String -> String -> Category -> String -> Element Classes variation msg
viewVote model icon preText category postText =
    row VoteCountItem
        [ padding 6, spacing 5, height (px 32) ]
        [ el VoteEmoji [ moveUp 4 ] (text icon)
        , text preText
        , text <| String.toLower <| translate model.language (Category.toName category)
        , text postText
        ]


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
