var App = require("./Main.elm");

var languages = navigator.languages || ["en"];
var rootNode = document.getElementById("app");
rootNode.innerHTML = "";

App.Main.embed(rootNode, { languages });

if (!process.env.DEBUG && "serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js");
}
