port module Main exposing (..)

import Data.Category as Category exposing (Category)
import Data.Votes as Votes exposing (PeopleVote, RobotVote, VerifiedVote, VotesResponse)
import Element exposing (..)
import Element.Attributes exposing (..)
import Helpers exposing (onClickStopPropagation)
import Html exposing (Html)
import Html.Attributes
import Json.Encode
import List.Extra
import Locale.Languages exposing (Language)
import Locale.Locale as Locale exposing (translate)
import Locale.Words as Words exposing (LocaleKey)
import RemoteData exposing (..)
import Stylesheet exposing (..)


type alias Model =
    { url : String, title : String, votes : WebData VotesResponse, language : Language }


type alias Flags =
    { languages : List String }


type Msg
    = OpenFlagPopup
    | VotesResponse (WebData VotesResponse)
    | AddVote { categoryId : Int }


port openFlagPopup : { url : String, title : String } -> Cmd msg


port addVote : ({ categoryId : Int } -> msg) -> Sub msg


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
    ( { url = "http://www.google.com"
      , title = ""
      , votes = NotAsked
      , language = Locale.fromCodeArray flags.languages
      }
    , Votes.getVotes "http://www.google.com" ""
        |> RemoteData.sendRequest
        |> Cmd.map VotesResponse
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    addVote AddVote


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenFlagPopup ->
            ( model, openFlagPopup { url = model.url, title = model.title } )

        VotesResponse response ->
            ( { model | votes = response }, Cmd.none )

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


view : Model -> Html Msg
view model =
    Element.layout stylesheet <|
        column NoStyle
            []
            [ flagButtonAndVotes model
            , explanation
            ]


flagButtonAndVotes : Model -> Element Classes variation Msg
flagButtonAndVotes model =
    let
        translate =
            Locale.translate model.language

        viewVerifiedVote vote =
            viewVote (Category.toEmoji vote.category) "" vote.category (translate Words.Verified)

        isValidUrl =
            String.startsWith "http"
    in
    if isValidUrl model.url then
        column General
            [ spacing 5, padding 5, minWidth (px 130) ]
            (case model.votes of
                Success votes ->
                    case votes.verified of
                        Just vote ->
                            [ viewVerifiedVote vote ]

                        Nothing ->
                            [ flagButton model, viewVotes votes ]

                Failure _ ->
                    [ flagButton model
                    , el VoteCountItem [ padding 6 ] (text <| translate Words.LoadingError)
                    ]

                _ ->
                    [ flagButton model ]
            )
    else
        el General [ padding 5 ] (text <| translate Words.InvalidUrlError ++ model.url)


flagButton : Model -> Element Classes variation Msg
flagButton model =
    button Button
        [ padding 4, onClickStopPropagation OpenFlagPopup ]
        (text <| Locale.translate model.language Words.FlagButton)


viewVotes : VotesResponse -> Element Classes variation Msg
viewVotes votes =
    let
        viewRobotVote ( category, chance ) =
            viewVote "\x1F916" (toString chance ++ "%") category ""

        viewPeopleVote vote =
            viewVote (Category.toEmoji vote.category) (toString vote.count) vote.category ""
    in
    column NoStyle
        [ spacing 5 ]
        [ case Votes.bestRobotGuess votes.robot of
            Just bestGuess ->
                viewRobotVote bestGuess

            Nothing ->
                empty
        , column NoStyle [ spacing 5 ] (List.map viewPeopleVote votes.people)
        ]


viewVote : String -> String -> Category -> String -> Element Classes variation msg
viewVote icon preText category postText =
    row VoteCountItem
        [ padding 6, spacing 5, height (px 26) ]
        [ el VoteEmoji [ moveUp 4 ] (text icon)
        , text preText
        , text (Category.toName category)
        , text postText
        ]


staticView : Html Msg
staticView =
    view (Tuple.first <| init { languages = [ "pt" ] })


explanation : Element Classes variation msg
explanation =
    let
        text =
            "<h1>Humanos e Robôs trabalhando junto contra os Fake News</h1>"
                ++ "<p>"
                ++ "  O Detector de Fake News é uma extensão para o"
                ++ "  <a href='https://chrome.google.com/webstore/detail/fake-news-detector/alomdfnfpbaagehmdokilpbjcjhacabk'>Chrome</a>"
                ++ "  e"
                ++ "  <a href='https://addons.mozilla.org/en-US/firefox/addon/fakenews-detector/'>Firefox</a>"
                ++ "  que permite detectar e classificar direto do seu feed do Facebook as notícias como <b>Legítimas</b>,"
                ++ "  <b>Fake News</b>, <b>Click Bait</b>, <b>Extremamente Tendenciosa</b> ou <b>Sátira</b>."
                ++ "</p>"
                ++ "<a href='https://chrome.google.com/webstore/detail/fake-news-detector/alomdfnfpbaagehmdokilpbjcjhacabk'><img height='58' src='static/add-to-chrome.png' /></a>"
                ++ "<a href='https://addons.mozilla.org/en-US/firefox/addon/fakenews-detector/'><img height='58' src='static/add-to-firefox.png'  /></a>"
                ++ "<p>"
                ++ "  Ao classificar uma notícia, outras pessoas que tem a extensão vão ver a sua sinalização,"
                ++ "  ficarão mais atentas e também poderão sinalizar. Essas informações são guardadas em um"
                ++ "  banco de dados, e são lidas pelo nosso robô, o"
                ++ "  <a href='https://github.com/fake-news-detector/robinho'>Robinho</a>."
                ++ "</p>"
                ++ "<p>"
                ++ "  O Robinho se baseia na informação dada por nós humanos, e vai aprendendo com o tempo a classificar"
                ++ "  automaticamente uma notícia como Fake News, Click Bait, etc, pelo seu texto. Com isso, mesmo novas"
                ++ "  notícias que ninguém nunca viu poderão ser rapidamente classificadas."
                ++ "</p>"
                ++ "<p>"
                ++ "  A extensão então mostra nas notícias do seu facebook a avaliação do robô e das pessoas:"
                ++ "</p>"
                ++ "<img src='static/clickbait.png' width='471' alt='Extensão mostrando que uma notícia foi classificada como click bait no facebook' />"
                ++ "<p>"
                ++ "  Quanto mais você avalia as notícias, mais você contribui para a construção de uma base para"
                ++ "  ensinar e melhorar o Robinho, que ainda está bem no início do seu desenvolvimento, veja, ele ainda"
                ++ "  é um bebê robô:"
                ++ "</p>"
                ++ "<img src='static/robinho.jpg' width='350' alt='Foto do Robinho'> <br />"
                ++ "<small>Créditos a <a href='http://www.paper-toy.fr/baby-robot-friend-de-drew-tetz/' target='_blank'>Drew Tetz</a> pela foto</small> <br />"
                ++ "<small>Créditos a <a href='https://twitter.com/laurapaschoal' target='_blank'>@laurapaschoal</a> pelo nome Robinho</small>"
                ++ "<h2>Motivação</h2>"
                ++ "<p>"
                ++ "  Em 2016, durante a eleição dos Estados Unidos, muitos sites de fake news foram criados,"
                ++ "  e propagados através das redes sociais, principalmente do Facebook, mas foram muitos,"
                ++ "  <b>muitos mesmo!</b> Tanto que as Fake News tiveram"
                ++ "  <a target='_blank' href='http://www.patheos.com/blogs/accordingtomatthew/2016/12/fake-news-stories-received-more-clicks-than-real-news-during-end-of-2016-election-season/'>"
                ++ "    mais cliques que as notícias reais."
                ++ "  </a>"
                ++ "</p>"
                ++ "<p>"
                ++ "  Um dos casos mais icônicos foi o de um morador da Macedônia que tinha"
                ++ "  <a target='_blank' href='https://www.wired.com/2017/02/veles-macedonia-fake-news/'>mais de 100 sites de fake news registrados</a>,"
                ++ "  chegando a ganhar milhares de dólares por mês com anúncios."
                ++ "</p>"
                ++ "<p>"
                ++ "  A maioria desses sites era pró-Trump, por que? O Macedônio era um defensor ferrenho do Trump?"
                ++ "  Não! Simplesmente porque o eleitorado do Trump era mais sucetível a acreditar e propagar Fake News."
                ++ "</p>"
                ++ "<p>"
                ++ "  Agora, em 2018, teremos eleições no Brasil, e há muitas páginas por aí que não se preocupam em"
                ++ "  conferir as fontes, e podem se aproveitar (e já estão se aproveitando) da mesma estratégia"
                ++ "  que beneficiou Donald Trump."
                ++ "</p>"
                ++ "<p>"
                ++ "  Além disso, ainda temos muitas publicações extremamente tendenciosas de todos os lados e"
                ++ "  os irritantes click-baits."
                ++ "</p>"
                ++ "<p>"
                ++ "  O Detector de Fake News é uma pequena iniciativa para tentar fazer alguma diferença na luta contra"
                ++ "  esse problema, unindo a boa vontade das pessoas (Crowdsourcing) com tecnologia (Machine Learning)"
                ++ "</p>"
                ++ "<h2>Como contribuir</h2>"
                ++ "<p>"
                ++ "  Só de baixar a extensão e sinalizar as notícias você já vai estar ajudando muito! Tanto outros"
                ++ "  usuários, quanto no desenvolvimento do Robinho."
                ++ "</p>"
                ++ "<p>"
                ++ "  Mas se você é programador ou cientista de dados, o Detector de Fake News é um projeto de"
                ++ "  código aberto que precisa muito da sua ajuda! Todos os repositórios estão disponíveis em:"
                ++ "  <a href='https://github.com/fake-news-detector'>https://github.com/fake-news-detector</a>."
                ++ "</p>"
                ++ "<p>"
                ++ "  As tecnologias também são muito empolgantes: usamos Elm com WebExtensions para"
                ++ "  a extensão, Rust para a API e Python para Machine Learning. Não conhece? Não tem problema, afinal o objetivo do"
                ++ "  projeto é justamente aprender essas tecnologias enquanto ajuda o mundo."
                ++ "</p>"
                ++ "<p>"
                ++ "  Se quiser ajudar, dê uma olhada no nosso <a href='https://github.com/fake-news-detector/fake-news-detector.github.io/blob/master/ROADMAP.md'>ROADMAP</a> (em inglês) para entender a direção do projeto, e dê uma olhada também nas <a href='https://github.com/fake-news-detector'>issues do github dos projetos</a>."
                ++ "</p>"
                ++ "<p>"
                ++ "  Se você ficou interessado mas tem dúvidas de como pode ajudar, me procure no twitter,"
                ++ "  <a href='https://twitter.com/_rchaves_'>@_rchaves_</a>."
                ++ "</p>"
    in
    html <|
        Html.div
            [ Html.Attributes.property "innerHTML"
                (Json.Encode.string text)
            ]
            []
