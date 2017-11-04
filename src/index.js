var App = require("./Main.elm");

var rootNode = document.getElementById("app");
rootNode.innerHTML = "";
App.Main.embed(rootNode);

if (!process.env.DEBUG && "serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js");
}
