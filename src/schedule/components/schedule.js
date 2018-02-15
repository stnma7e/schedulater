import $ from 'jquery';
import React from 'react';
import PropTypes from 'prop-types';
import ReactDOM from 'react-dom';
import {
    Foundation,
    Button as ReactButton
} from 'react-foundation';
import CourseSelector from './containers/courseSelectorContainer';
import Filters from './containers/filterContainer';
import Calendar from './calendar';
import CourseList from './containers/courseList';
import { FlatCourse } from '../../common';

import Elm from 'react-elm-components'
import { Main } from '../../../elmsrc/Main.elm'

export default class Schedule extends React.Component {
    render() {
        let ports = function(){}
        function setupPorts(p) {
            ports = p
        }

        let appliedCombos = [];
        if (this.props.combos.length > this.props.schedIndex) {
            appliedCombos = applyComboToClasses(this.props.courses, this.props.combos[this.props.schedIndex])
            console.log(this.props.combos[this.props.schedIndex])
        }

        ports(4)

        return (
            <div>
                <div>
                    <Elm src={Main} ports={setupPorts} />
                </div>

                <div className="grid-container">
                    <div id="calendar_row" className="grid-x grid-padding-x grid-padding-y">
                        <div className="cell small-12 large-8 small-order-1 large-order-1">
                            <Calendar
                                className="grid-x"
                                classes={appliedCombos}
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
                                            onClick={this.props.setSchedIndex(false, this.props.schedIndex, this.props.schedCount)}>
                                        Previous Schedule
                                    </ReactButton>
                                </div>
                                <div className="cell small-4">
                                    <ReactButton
                                            className='sched_button cell small-12'
                                            onClick={this.props.setSchedIndex(true, this.props.schedIndex, this.props.schedCount)}>
                                        Next Schedule
                                    </ReactButton>
                                </div>
                                <div className="cell small-1">
                                    <ReactButton
                                        className='sched_button cell small-12'
                                        onClick={this.props.requestCourses}>&#x21bb;</ReactButton>
                                </div>
                            </div>
                        </div>
                            <div className="cell small-12 large-4 large-order-2 small-order-2">
                                <CourseSelector />
                                <CourseList />
                            </div>
                    </div>

                    <Filters className="cell small-12 small-order-3 large-3 large-order-3" />
                </div>

            </div>
        )
    }
}

Schedule.propTypes = {
    schedCount: PropTypes.number,
    classes: PropTypes.arrayOf(PropTypes.instanceOf(FlatCourse)),
    combos: PropTypes.arrayOf(PropTypes.arrayOf(PropTypes.number)),
    schedIndex: PropTypes.number,
    lockedIn: PropTypes.arrayOf(PropTypes.number),

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
