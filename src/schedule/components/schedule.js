import $ from 'jquery';
import React from 'react';
import ReactDOM from 'react-dom';
import {
  Foundation,
  Button as ReactButton
} from 'react-foundation';

import CourseSelector from './containers/courseSelectorContainer';
import Filters from './containers/filterContainer';
import Calendar from './calendar';
import CourseLock from './courseLock';

export default class ScheduleCalendar extends React.Component {
  render() {
    let apppliedCombos = [];
    if ( typeof this.props.classes != "undefined"
      && typeof this.props.combos  != "undefined"
      && this.props.combos.length > this.props.schedIndex
    ) {
      apppliedCombos = applyComboToClasses(this.props.classes, this.props.combos[this.props.schedIndex])
      console.log(this.props.combos[this.props.schedIndex])
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
                  <strong>Current Schedule:</strong> {this.props.schedIndex + 1}
                </p>
                <p>
                  <strong>Total Available Schedules:</strong> {this.props.combos.length}
                </p>
              </div>
              <div className="cell small-4">
                <ReactButton
                    className='sched_button cell small-12'
                    onClick={this.props.setSchedIndex(false, this.props.schedIndex, this.props.schedCount)}
                >
                    Previous Schedule
                </ReactButton>
              </div>
              <div className="cell small-4">
                <ReactButton
                    className='sched_button cell small-12'
                    onClick={this.props.setSchedIndex(true, this.props.schedIndex, this.props.schedCount)}
                >
                    Next Schedule
                </ReactButton>
              </div>
              <div className="cell small-1">
                <ReactButton className='sched_button cell small-12' onClick={this.props.requestCourses}>&#x21bb;</ReactButton>
              </div>
            </div>

            <div className="grid-x grid-margin-x small-order-4">
              <hr className="cell small-centered small-12"/>
              <div className="cell courses_table small-12">
                <CourseSelector/>
              </div>
            </div>
          </div>

          <Filters className="cell small-12 small-order-3 large-3 large-order-3" />
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
