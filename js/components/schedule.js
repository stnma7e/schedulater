import $ from 'jquery';
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
require('../../node_modules/foundation-sites/dist/js/foundation.min.js');
require("../../dist/app.scss");

import ActiveInstructorFilter from './containers/activeInstructorFilter.js';
import CourseSelector from './course_selector.js';
import Filter from './filter.js';
import Calendar from './calendar.js';

export default class ScheduleCalendar extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      schedNumber: 0,
      coursesHaveUpdated: false,
    };

    this.nextSched = this.nextSched.bind(this);
    this.lastSched = this.lastSched.bind(this);
    this.requestClasses = this.requestClasses.bind(this);
    this.addClasses = this.addClasses.bind(this);
    this.removeClasses = this.removeClasses.bind(this);
    this.handleCreditHours = this.handleCreditHours.bind(this);
  }

  componentDidMount() {
    $("#start_time").timepicker({
      minTime: "7:00am",
      maxTime: "10:00pm",
      step: 15});
    $("#end_time").timepicker({
      minTime: "7:00am",
      maxTime: "10:00pm",
      step: 15});
  }

  requestClasses() {
    var start_time = $('#start_time').timepicker('getTime').toTimeString();
    var end_time   = $('#end_time').timepicker('getTime').toTimeString();

    var instructor_filter = {};
    for (var course in this.state.disabledInstructors) {
      instructor_filter[course] = Array.from(this.state.disabledInstructors[course])
    }

    this.setState({
      schedNumber: 0,
      coursesHaveUpdated: false
    });

    this.props.requestCourses(this.state.coursesHaveUpdated, {
      courses: this.props.courses,
      time_filter: {
        start: start_time,
        end:   end_time
      },
      credit_filter: {
        min_hours: this.props.courseFilters.creditHours.minHours,
        max_hours: this.props.courseFilters.creditHours.maxHours
      },
      instructor_filter: this.props.instructors
    });
  }

  addClasses(rows) {
    this.props.addClasses(rows);

    this.setState({
      coursesHaveUpdated: true,
    }, () => {
      this.requestClasses()
    });
  }

  removeClasses(rows) {
    if (typeof rows == "undefined") {
      console.error("rows were undefined")
      return
    }

    this.props.removeClasses(rows)

    this.setState({
      coursesHaveUpdated: true,
    }, () => {
      this.requestClasses()
    });
  }

  lastSched() {
    if (this.state.schedNumber > 0) {
      this.setState(prevState => ({
        schedNumber: prevState.schedNumber - 1
      }), () => {
        console.info(this.state.schedNumber);
      });
    }
  }

  nextSched() {
    if (this.state.schedNumber < this.props.schedCount - 1) {
      this.setState(prevState => ({
        schedNumber: prevState.schedNumber + 1
      }), () => {
        console.info(this.state.schedNumber);
      });
    }
  }

  handleCreditHours(minHours, event) {
    if (event.target.value < 1 || event.target.value > 18) {
      return
    }

    if (minHours) {
      if (this.props.courseFilters.creditHours.minHours > event.target.value) {
        // minHours was decremented
        this.props.changeCreditHours(false, true)
      } else {
        this.props.changeCreditHours(true, true)
      }
    } else {
      if (this.props.courseFilters.creditHours.maxHours > event.target.value) {
        // minHours was decremented
        this.props.changeCreditHours(false, false)
      } else {
        this.props.changeCreditHours(true, false)
      }
    }
  }

  render() {
    return (
      <div>
        <div id="calendar_row" className="grid-x grid-padding-x">
          <div className="cell small-12 large-9">
            <Calendar
              className="grid-x"
              classes={this.props.classes}
              combo={this.props.combos[this.state.schedNumber]}
            />

            <div className="grid-x grid-padding-x">
              <div className="cell small-5">
                <ReactButton className='sched_button cell small-12' onClick={this.lastSched}>Previous Schedule</ReactButton>
              </div>
              <div className="cell small-5">
                <ReactButton className='sched_button cell small-12' onClick={this.nextSched}>Next Schedule</ReactButton>
              </div>
              <div className="cell small-2">
                <ReactButton className='sched_button cell small-12' onClick={this.requestClasses}>&#x21bb;</ReactButton>
              </div>
            </div>

          </div>

          <div id="filters" className="cell small-12 large-3">
            <h5>Filters:</h5>
            <hr/>
          <div className="grid-x grid-padding-x small-up-3 large-up-1">


            <Filter filterType="Time">
              <div className="cell small-6">
                Start
                <input
                  className="ui-timepicker-input"
                  type="text"
                  id="start_time"
                  defaultValue="08:00"
                />
              </div>
              <div className="cell small-6">
                End
                <input
                  className="ui-timepicker-input"
                  type="text"
                  id="end_time"
                  defaultValue="19:00"
                />
              </div>
            </Filter>

            <Filter filterType="Credit Hours">
              <div className="cell small-6">
                Minimum #
                <input
                  type="number"
                  id="minHours"
                  value={this.props.courseFilters.creditHours.minHours}
                  onChange={(event) => {this.handleCreditHours(true, event)}}
                />
              </div>
              <div className="cell small-6">
                Maximum #
                <input
                  type="number"
                  id="maxHours"
                  value={this.props.courseFilters.creditHours.maxHours}
                  onChange={(event) => {this.handleCreditHours(false, event)}}
                />
              </div>
            </Filter>

            <ActiveInstructorFilter />

          </div>
          </div>

        </div>

        <div className="grid-x">
          <hr className="cell small-centered small-11 large-11 large-centered end"/>
          <div className="cell courses_table small-12 large-9 end">
            <CourseSelector requestClassesFunction={this.requestClasses}
                            addClasses={this.addClasses}
                            removeClasses={this.removeClasses}
            />,
          </div>
        </div>
      </div>
    )
  }
}
