var App = require("./Main.elm");

var path = window.location.pathname;
var browerLanguages = navigator.languages || ["en"];

// TODO: move this language logic to Elm
var languages = browerLanguages
  .map(function(language) {
    return language.substr(0, 2);
  })
  .reverse();
var isPortuguese = languages.indexOf("pt") >= 0;
var isSpanish =
  !isPortuguese && languages.lastIndexOf("es") > languages.lastIndexOf("en");

var language = isPortuguese ? "pt" : isSpanish ? "es" : "en";
if (path === "/") {
  window.history.pushState(null, "", "/" + language);
} else {
  language = path.replace("/", "");
}

var rootNode = document.getElementById("app");
rootNode.innerHTML = "";

App.Main.embed(rootNode, { languages: [language] });

if (!process.env.DEBUG && "serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js");
}
