const webpack = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const fs = require("fs");

// Generates htmls for each page generates by elm-static-html
const pages = fs.readdirSync("./build/static/pages");
const pagesPlugins = pages.map(
  page =>
    new HtmlWebpackPlugin({
      template: "src/index.ejs",
      filename: page,
      page: page.replace(".html", ""),
      alwaysWriteToDisk: true
    })
);

const config = {
  entry: "./src/index.js",
  output: {
    path: `${__dirname}/build`,
    filename: "[name].[hash].js"
  },
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: process.env.DEBUG
          ? ["elm-hot-loader", "elm-webpack-loader?debug=true"]
          : ["elm-webpack-loader"]
      },
      {
        test: /\.html$/,
        use: ["raw-loader"]
      }
    ]
  },
  devServer: {
    host: "0.0.0.0",
    disableHostCheck: true
  },
  plugins: pagesPlugins.concat([
    new webpack.EnvironmentPlugin(["DEBUG"]),
    new CopyWebpackPlugin([
      {
        from: "src/static",
        to: "static"
      }
    ])
  ])
};

module.exports = config;
