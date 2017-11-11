const webpack = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

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
  plugins: [
    new webpack.EnvironmentPlugin(["DEBUG"]),
    new HtmlWebpackPlugin({
      template: "src/pages/index.ejs",
      filename: "index.html"
    }),
    new HtmlWebpackPlugin({
      template: "src/pages/more.ejs",
      filename: "more.html",
      inject: false
    }),
    new CopyWebpackPlugin([
      {
        from: "src/static",
        to: "static"
      }
    ])
  ]
};

module.exports = config;
