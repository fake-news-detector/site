module FlagLink exposing (..)

import Data.Category as Category exposing (Category(..))
import Data.Votes as Votes
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input as Input exposing (hiddenLabel, placeholder)
import Helpers exposing (humanizeError, onClickStopPropagation)
import Locale.Languages exposing (Language(..))
import Locale.Locale as Locale exposing (translate)
import Locale.Words as Words
import RemoteData exposing (..)
import Stylesheet exposing (..)


type alias Model =
    { state : FlaggingState
    , selectedCategory : Maybe Category
    , submitResponse : WebData ()
    }


type FlaggingState
    = Opened
    | Closed
    | Flagged


init : Model
init =
    { state = Closed
    , selectedCategory = Nothing
    , submitResponse = NotAsked
    }


type Msg
    = OpenFlagForm
    | CloseFlagForm
    | SelectCategory Category
    | SubmitFlag String String
    | SubmitResponse (WebData ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenFlagForm ->
            ( { model | state = Opened }, Cmd.none )

        CloseFlagForm ->
            ( init, Cmd.none )

        SelectCategory category ->
            ( { model | selectedCategory = Just category }, Cmd.none )

        SubmitFlag uuid url ->
            case model.selectedCategory of
                Just selectedCategory ->
                    ( { model | submitResponse = RemoteData.Loading }
                    , Votes.postVote uuid url "" selectedCategory
                        |> RemoteData.sendRequest
                        |> Cmd.map SubmitResponse
                    )

                Nothing ->
                    ( model, Cmd.none )

        SubmitResponse response ->
            if isSuccess response then
                ( { model | state = Flagged }, Cmd.none )
            else
                ( { model | submitResponse = response }, Cmd.none )


flagLink : String -> String -> Language -> Model -> Element Classes variation Msg
flagLink uuid url language model =
    case model.state of
        Opened ->
            flagForm uuid url language model

        Closed ->
            paragraph NoStyle
                [ verticalCenter ]
                [ el NoStyle [ paddingRight 5 ] (text <| translate language Words.HelpImproveResult)
                , flagButton language model
                ]

        Flagged ->
            text (translate language Words.ContentFlagged)


flagButton : Language -> Model -> Element Classes variation Msg
flagButton language model =
    button Button
        [ padding 4, onClick OpenFlagForm ]
        (text <| Locale.translate language Words.FlagButton)


flagForm : String -> String -> Language -> Model -> Element Classes variation Msg
flagForm uuid url language model =
    let
        translate =
            Locale.translate language
    in
    node "form" <|
        column NoStyle
            [ spacing 15 ]
            [ Input.radio NoStyle
                [ spacing 15
                ]
                { onChange = SelectCategory
                , selected = model.selectedCategory
                , label = Input.labelAbove empty
                , options = []
                , choices =
                    [ flagChoice Legitimate
                        (translate Words.Legitimate)
                        (translate Words.LegitimateDescription)
                    , flagChoice FakeNews
                        (translate Words.FakeNews)
                        (translate Words.FakeNewsDescription)
                    , flagChoice ClickBait
                        (translate Words.ClickBait)
                        (translate Words.ClickBaitDescription)
                    , flagChoice ExtremelyBiased
                        (translate Words.ExtremelyBiased)
                        (translate Words.ExtremelyBiasedDescription)
                    , flagChoice Satire
                        (translate Words.Satire)
                        (translate Words.SatireDescription)
                    , flagChoice NotNews
                        (translate Words.NotNews)
                        (translate Words.NotNewsDescription)
                    ]
                }
            , case model.submitResponse of
                Failure err ->
                    paragraph ErrorMessage [ padding 6 ] [ text (humanizeError language err) ]

                _ ->
                    empty
            , el NoStyle
                []
                (button BlueButton
                    [ padding 5, onClickStopPropagation (SubmitFlag uuid url) ]
                    (if isLoading model.submitResponse then
                        text <| translate Words.Loading
                     else
                        text <| translate Words.FlagSubmitButton
                    )
                )
            ]


flagChoice : Category -> String -> String -> Input.Choice Category Classes variation msg
flagChoice category title description =
    Input.choice category <|
        Element.column NoStyle
            [ spacing 12 ]
            [ bold title
            , paragraph NoStyle [] [ text description ]
            ]
