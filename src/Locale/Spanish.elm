module Locale.Spanish exposing (..)

import Locale.Words exposing (LocaleKey(..))


translate : LocaleKey -> String
translate localeValue =
    case localeValue of
        Loading ->
            "Cargando..."

        FlagContent ->
            "Señalar contenido"

        FlagQuestion ->
            "¿Cuál de las siguientes opciones define mejor este contenido?"

        FlagSubmitButton ->
            "Señalar"

        Legitimate ->
            "Auténtico"

        LegitimateDescription ->
            "Contenido verdadero, no intenta engañar a nadie, de ninguna manera"

        FakeNews ->
            "Fake News"

        FakeNewsDescription ->
            "Noticia falsa, engaña al lector, difunde rumores"

        ClickBait ->
            "Click Bait"

        ClickBaitDescription ->
            "Título no explica la noticia completa de propósito sólo para ganar clics"

        ExtremelyBiased ->
            "Extremadamente Tienencioso"

        ExtremelyBiasedDescription ->
            "Sólo muestra un lado de la historia, interpreta de forma exagerada algunos puntos, sin ponderación con otros"

        Satire ->
            "Sátira"

        SatireDescription ->
            "Contenido intencionalmente falso, con fines humorísticos"

        NotNews ->
            "No es noticia"

        NotNewsDescription ->
            "Meme, contenido personal o cualquier otra cosa no periodística"

        Verified ->
            "(verificado)"

        FlagButton ->
            "🏴 Señalar"

        InvalidUrlError ->
            "Url inválida: "

        LoadingError ->
            "error al cargar"

        TimeoutError ->
            "Timeout: operación tomó demasiado tiempo"

        NetworkError ->
            "Error de red: compruebe su conexión a Internet"

        Explanation ->
            explanation


explanation : String
explanation =
    """

# Humanos y Robots trabajando juntos contra los Fake News

El Fake News Detector es una extensión para [Chrome](https://chrome.google.com/webstore/detail/fake-news-detector/alomdfnfpbaagehmdokilpbjcjhacabk)
y [Firefox](https://addons.mozilla.org/en-US/firefox/addon/fakenews-detector/)
que le permite detectar y señalar noticias directamente de tu Facebook en
**Auténtico**, **Fake News**, **Click Bait**, **Extremamente Tendencioso**, **Sátira** ou **No es noticia**.

[<img height="58" src="static/add-to-chrome.png" alt="Adicionar ao Chrome" />](https://chrome.google.com/webstore/detail/fake-news-detector/alomdfnfpbaagehmdokilpbjcjhacabk)
[<img height="58" src="static/add-to-firefox.png" alt="Adicionar ao Firefox" />](https://addons.mozilla.org/en-US/firefox/addon/fakenews-detector/)

Al clasificar una noticia, otras personas que tienen la extensión van a ver su señalización,
quedarán más atentas y también podrán señalar. Esta información se guarda en una base de datos,
y es leída por nuestro robot, el [Robinho](https://github.com/fake-news-detector/robinho).

El Robinho se basa en la información dada por nosotros humanos, y va aprendiendo
con el tiempo a clasificar automáticamente una noticia como Fake News, Click Bait,
etc, por su texto. Con eso, incluso nuevas noticias que nadie nunca vio pueden ser
rápidamente clasificadas.

La extensión entonces muestra en las noticias de su facebook la evaluación del robot y de las personas:

<img src="static/clickbait.png" width="471" alt="Extensión que muestra que una noticia fue clasificada como clickbait en facebook" />

Cuanto más tu evalúas las noticias, más contribuyes a la construcción de una base para enseñar y
mejorar el Robinho, que aún está muy al principio de su desarrollo, vea, todavía es un bebé robot:

<img src="static/robinho.jpg" width="350" alt="Foto de Robinho">

<small>Créditos a <a href="http://www.paper-toy.fr/baby-robot-friend-de-drew-tetz/" target="_blank">Drew Tetz</a> por la foto</small> <br />
<small>Créditos a <a href="https://twitter.com/laurapaschoal" target="_blank">@laurapaschoal</a> por el nombre Robinho</small>

## Motivación

En 2016, durante la elección de Estados Unidos, muchos sitios de fake news fueron
creados, y propagados a través de las redes sociales, principalmente de Facebook.
Fueron tantos, que las Fake News tuvieron
<a target="_blank" href="http://www.patheos.com/blogs/accordingtomatthew/2016/12/fake-news-stories-received-more-clicks-than-real-news-during-end-of-2016-election-season/">
más clics que las noticias reales.
</a>

Uno de los casos más icónicos fue el de un habitante de Macedonia que tenía
<a target="_blank" href="https://www.wired.com/2017/02/veles-macedonia-fake-news/">más de 100 sitios de fake news registrados</a>,
llegando a ganar miles de dólares al mes con anuncios.

La mayoría de estos sitios eran pro-Trump, por qué? ¿El Macedonio era un defensor
férreo del Trump? ¡No necesariamente! Pero él se dio cuenta de que el electorado
de Trump era más acertado a creer y propagar Fake News.

Ahora, en 2018, tendremos elecciones en Brasil, y hay muchas páginas por ahí que
no se preocupan por conferir las fuentes, y pueden aprovecharse (y ya se están aprovechando)
de la misma estrategia que benefició a Donald Trump.

Además, todavía tenemos muchas publicaciones extremadamente tendenciosas de todos
los lados y los irritantes click-baits.

El Detector de Fake News es una pequeña iniciativa para intentar hacer alguna
diferencia en la lucha contra este problema, uniendo la buena voluntad de las
personas (Crowdsourcing) con tecnología (Machine Learning)

## Cómo contribuir

Sólo de bajar la extensión y señalar las noticias usted ya va a estar ayudando mucho, tanto otros
usuarios, como en el desarrollo de Robinho.

Pero si usted es desarrollador o data scientist, el Detector de Fake News es un
proyecto de código abierto que necesita mucho de su ayuda! Todos los repositorios
están disponibles en:
[https://github.com/fake-news-detector](https://github.com/fake-news-detector).

Las tecnologías también son muy emocionantes: usamos Elm con WebExtensions para
la extensión, Rust para la API y Python para Machine Learning. ¿No conoce? No
tiene problema, al final el objetivo del proyecto es justamente aprender esas
tecnologías mientras ayuda al mundo.

Si desea ayudar, eche un vistazo a nuestro [ROADMAP](https://github.com/fake-news-detector/site/blob/master/ROADMAP.md)
(en inglés) para entender la dirección del proyecto, y mire también
las [issues del github de los proyectos](https://github.com/fake-news-detector).

Si usted se interesó pero tiene dudas de cómo puede ayudar, me busque en el twitter,
[@_rchaves_](https://twitter.com/_rchaves_).

"""
