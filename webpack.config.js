const ExtractTextPlugin = require('extract-text-webpack-plugin');
const extractSass = new ExtractTextPlugin({
//    filename: "[name].[contenthash].css",
    filename: "dist/bundle.css",
    disable: process.env.NODE_ENV === "development"
});
var webpack = require('webpack');

module.exports = {
  entry: './src/index.js',
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
    ],
    rules: [
        {
            test: /\.scss$/,
            use: extractSass.extract({
                use: [{
                        loader: "css-loader" // translates CSS into CommonJS
                    }, {
                        loader: "sass-loader" // compiles Sass to CSS
                    }],
                fallback: "style-loader"
            })
        },
        {
            test: /\.jsx?$/,
            loader: 'babel-loader',
            exclude: /node_modules/,
            query: {
                presets: ['es2015', 'react']
            }
        }
    ]
  },
  plugins: [
      extractSass,
      new webpack.ProvidePlugin({
        $: "jquery",
        jQuery: "jquery"
      }),
      new ExtractTextPlugin({ filename: 'bundle.css', disable: false, allChunks: true })
  ]
};
