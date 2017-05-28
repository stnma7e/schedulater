import $ from 'jquery';
import fullCalendar from 'fullcalendar';
import timepicker from 'timepicker';
import React from 'react';
import ReactDOM from 'react-dom';
import {
  Foundation,
  Button as ReactButton
} from 'react-foundation';
import {DataTable} from 'datatables.net';
import {Button} from 'datatables.net-buttons-zf';
import {Select} from 'datatables.net-select';
require('../node_modules/foundation-sites/dist/js/foundation.min.js');
require("../dist/app.scss");

import ActiveInstructorFilter from './components/containers/activeInstructorFilter.js';
import CoursedSchedule from './components/containers/coursedSchedule.js';
import {CourseSelector} from './components/course_selector.js';

import { createStore, applyMiddleware } from 'redux'
import thunkMiddleware from 'redux-thunk'
import { Provider } from 'react-redux';
import scheduleApp from "./reducers";
import { addInstructor, addCourse, removeCourse, removeAllCourses } from './actions';

$(document).ready(function() {
  let store = createStore(scheduleApp, applyMiddleware(thunkMiddleware));

  let unsubscribe = store.subscribe(() =>
    console.log(store.getState())
  )

  ReactDOM.render(
    <Provider store={store}>
      <CoursedSchedule/>
    </Provider>,
    document.getElementById('calendar_container')
  );
  $(document).foundation();
})
