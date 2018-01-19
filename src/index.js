import App from "./Main.elm";
import uuidv4 from "uuid/v4";

var path = window.location.pathname;
var browerLanguages = navigator.languages || ["en"];

const uuid = localStorage.getItem("uuid") || uuidv4();
localStorage.setItem("uuid", uuid);

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

App.Main.embed(rootNode, { languages: [language], uuid });

if (!process.env.DEBUG && "serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js");
}
