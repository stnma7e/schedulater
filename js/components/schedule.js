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

import CourseSelector from './course_selector.js';
import Filters from './filter.js';
import Calendar from './calendar.js';
import CourseLock from './courseLock.js';

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
      courses: this.props.selectedCourses,
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
    } else {
      this.setState(prevState => ({
        schedNumber: this.props.schedCount - 1
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
    } else {
      this.setState(prevState => ({
        schedNumber: 0
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

  componentWillReceiveProps(nextProps) {
    if (nextProps.combos.length > 0) {
      this.setState({
          schedNumber: 0
      })
    }
  }

  render() {
    let apppliedCombos = [];
    if ( typeof this.props.classes != "undefined"
      && typeof this.props.combos  != "undefined"
      && this.props.combos.length > this.state.schedNumber
    ) {
      apppliedCombos = applyComboToClasses(this.props.classes, this.props.combos[this.state.schedNumber])
      console.log(this.props.combos[this.state.schedNumber])
    }

    return (
      <div className="grid-container">
        <div id="calendar_row" className="grid-x grid-padding-x">

            <div className="cell grid-x grid-padding-x small-up-3">
              {this.props.classes.map((c, i) => {
                return (
                  <CourseLock key={i}
                    courseIndex={i}
                    course={c}
                    lockedIn={this.props.lockedIn}
                  />
                )
              })}
            </div>

          <div className="cell small-12 large-9 small-order-1 large-order-1">
            <Calendar
              className="grid-x"
              classes={apppliedCombos}
              lockCourseIndex={this.props.lockCourseIndex}
            />

            <div className="grid-x grid-padding-x small-order-2 large-order-2">
              <div className="cell small-3 scheduleInfo">
                <p>
                  <strong>Current Schedule:</strong> {this.state.schedNumber + 1}
                </p>
                <p>
                  <strong>Total Available Schedules:</strong> {this.props.combos.length}
                </p>
              </div>
              <div className="cell small-4">
                <ReactButton className='sched_button cell small-12' onClick={this.lastSched}>Previous Schedule</ReactButton>
              </div>
              <div className="cell small-4">
                <ReactButton className='sched_button cell small-12' onClick={this.nextSched}>Next Schedule</ReactButton>
              </div>
              <div className="cell small-1">
                <ReactButton className='sched_button cell small-12' onClick={this.requestClasses}>&#x21bb;</ReactButton>
              </div>
            </div>

            <div className="grid-x grid-margin-x small-order-4">
              <hr className="cell small-centered small-12"/>
              <div className="cell courses_table small-12">
                <CourseSelector requestClassesFunction={this.requestClasses}
                                addClasses={this.addClasses}
                                removeClasses={this.removeClasses}
                />,
              </div>
            </div>
          </div>

          <Filters
            className="cell small-12 small-order-3 large-3 large-order-3"
            handleCreditHours={this.handleCreditHours}
            minHours={this.props.courseFilters.creditHours.minHours}
            maxHours={this.props.courseFilters.creditHours.maxHours}
          />
        </div>
      </div>
    )
  }
}

export function applyComboToClasses(classes, combo) {
  return combo.map((combo_index, course_index) => {
    if (combo_index < 1) {
      return null
    } else {
      // we only need the a single class from each course time, so we can just
      // use the first one
      return Object.assign(classes[course_index].classes[combo_index - 1][0], {
        title: classes[course_index].title
      })
    }
  }).filter((x) => x != null)
}
