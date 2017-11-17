module Main exposing (..)

import Data.Category as Category exposing (Category)
import Data.Votes as Votes exposing (PeopleVote, RobotVote, VerifiedVote, VotesResponse)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input exposing (hiddenLabel, placeholder)
import Helpers exposing (onClickStopPropagation)
import Html exposing (Html)
import List.Extra
import Locale.Languages exposing (Language)
import Locale.Locale as Locale exposing (translate)
import Locale.Words exposing (LocaleKey(..))
import Markdown
import Ports exposing (..)
import RemoteData exposing (..)
import Stylesheet exposing (..)


type alias Model =
    { url : String
    , refreshUrlCounter : Int -- hack: http://package.elm-lang.org/packages/mdgriffith/style-elements/4.2.0/Element-Input#textKey
    , votes : WebData VotesResponse
    , language : Language
    }


type alias Flags =
    { languages : List String }


type Msg
    = OpenFlagPopup
    | VotesResponse (WebData VotesResponse)
    | AddVote { categoryId : Int }
    | ChangeUrl String
    | Submit
    | UseExample


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { url = ""
      , refreshUrlCounter = 0
      , votes = NotAsked
      , language = Locale.fromCodeArray flags.languages
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    addVote AddVote


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenFlagPopup ->
            ( model, openFlagPopup { url = model.url } )

        VotesResponse response ->
            ( { model | votes = response }, Cmd.none )

        ChangeUrl url ->
            ( { model | url = url }, Cmd.none )

        Submit ->
            if String.startsWith "http" model.url then
                ( { model | votes = RemoteData.Loading }
                , Votes.getVotes model.url ""
                    |> RemoteData.sendRequest
                    |> Cmd.map VotesResponse
                )
            else
                ( model, Cmd.none )

        AddVote { categoryId } ->
            let
                category =
                    Category.fromId categoryId

                isCategory voteCount =
                    voteCount.category == category

                peopleVotes =
                    case model.votes of
                        Success votes ->
                            if List.Extra.find isCategory votes.people == Nothing then
                                { category = category, count = 1 } :: votes.people
                            else
                                List.Extra.updateIf isCategory
                                    (\voteCount -> { voteCount | count = voteCount.count + 1 })
                                    votes.people

                        _ ->
                            [ { category = category, count = 1 } ]

                updatedVotes =
                    model.votes
                        |> RemoteData.map (\votes -> { votes | people = peopleVotes })
                        |> RemoteData.withDefault { verified = Nothing, robot = [], people = peopleVotes }
            in
            ( { model | votes = Success updatedVotes }, Cmd.none )

        UseExample ->
            { model | refreshUrlCounter = model.refreshUrlCounter + 1 }
                |> update (ChangeUrl "http://www.acritica.com/channels/cotidiano/news/droga-que-pode-causar-atitudes-canibais-e-apreendida-no-brasil")
                |> Tuple.first
                |> update Submit


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
                [ Element.Input.text UrlInput
                    [ padding 10 ]
                    { onChange = ChangeUrl
                    , value = model.url
                    , label = placeholder { text = translate model.language PasteLink, label = hiddenLabel "Url" }
                    , options = [ Element.Input.textKey (toString model.refreshUrlCounter) ]
                    }
                , button BlueButton [ width (percent 20) ] (text <| translate model.language Check)
                ]
            )
        , flagButtonAndVotes model
        ]


flagButtonAndVotes : Model -> Element Classes variation Msg
flagButtonAndVotes model =
    let
        translate =
            Locale.translate model.language

        viewVerifiedVote vote =
            viewVote model (Category.toEmoji vote.category) "" vote.category (translate Verified)

        isValidUrl url =
            String.startsWith "http" url || String.isEmpty url
    in
    if isValidUrl model.url then
        column General
            [ spacing 5, minWidth (px 130) ]
            (case model.votes of
                Success votes ->
                    case votes.verified of
                        Just vote ->
                            [ viewVerifiedVote vote ]

                        Nothing ->
                            [ viewVotes model votes ]

                Failure _ ->
                    [ el VoteCountItem [ padding 6 ] (text <| translate LoadingError)
                    ]

                RemoteData.Loading ->
                    [ text <| translate Locale.Words.Loading
                    ]

                _ ->
                    []
            )
    else
        el General [ padding 5 ] (text <| translate InvalidUrlError ++ model.url)


flagButton : Model -> Element Classes variation Msg
flagButton model =
    button Button
        [ padding 4, onClickStopPropagation OpenFlagPopup ]
        (text <| Locale.translate model.language FlagButton)


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
        , paragraph NoStyle [] [ text <| translate_ HelpImproveResult ]
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
    view (Tuple.first <| init { languages = [ lang ] })


staticViewPt : Html Msg
staticViewPt =
    staticView "pt"


staticViewEn : Html Msg
staticViewEn =
    staticView "en"


staticViewEs : Html Msg
staticViewEs =
    staticView "es"
