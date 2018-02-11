import React from 'react';
import ReactDOM from 'react-dom';
require('../node_modules/foundation-sites/dist/js/foundation.min.js');
require("../dist/app.scss");

import {
    createStore,
    applyMiddleware
} from 'redux'
import thunkMiddleware from 'redux-thunk'
import {
    Provider
} from 'react-redux';

import scheduleApp from "./schedule/reducers";
import Schedule from './schedule';

$(document).ready(function() {
    let store = createStore(scheduleApp, applyMiddleware(thunkMiddleware));

    let unsubscribe = store.subscribe(() =>
        console.log(store.getState())
    )

    ReactDOM.render(
        <Provider store={store}>
      <Schedule/>
    </Provider>,
        document.getElementById('calendar_container')
    );
    $(document).foundation();
})
