const ExtractTextPlugin = require('extract-text-webpack-plugin');
var webpack = require('webpack');

module.exports = {
  entry: './index.jsx',
  output: {
    filename: 'dist/bundle.js'
  },
  module: {
    loaders: [
      {
          test: /\.jsx?$/,
          loader: 'babel-loader',
          exclude: /node_modules/,
          query: {
              presets: ['es2015', 'react']
          }
      },
      {
        test: /\.scss$/,
        loaders: ["style-loader", "css-loader", "sass-loader"]
      },
      {
        test: /\.sass$/,
        exclude: "node_modules/"
        use: ExtractTextPlugin.extract({
          fallbackLoader: "style-loader", // Will inject the style tag if plugin fails
          loader: "css-loader!sass-loader",
        }),
      },
    ],
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    }),
    new ExtractTextPlugin({ filename: 'bundle.css', disable: false, allChunks: true })
  ]
};
