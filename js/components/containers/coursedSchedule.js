import ScheduleCalendar from '../schedule.js'
import { connect } from 'react-redux'
import { addCourse, removeCourse, removeAllCourses, changeCreditHours } from "../../actions";
import fetchCourses from '../../actions/fetchCourses.js'

const mapStateToProps = (state) => {
  if (  state.courseRequests.length < 1
     || typeof state.courseRequests[state.courseRequests.length-1].courses == "undefined"
  ) {
    return {
      schedule: { "courses": { "schedule": [] } },
      schedCount: 0,
      classes: [],
      combos:  [],
      courses: Array.from(state.currentCourses),
      instructors: state.instructorMap,
      courseFilters: state.courseFilters
    }
  }

  return {
    schedCount:    state.courseRequests[state.courseRequests.length-1].courses.sched_count,
    classes:       state.courseRequests[state.courseRequests.length-1].courses.flat_courses,
    combos:        state.courseRequests[state.courseRequests.length-1].courses.scheds,
    courses:       Array.from(state.currentCourses),
    instructors:   state.instructorMap,
    courseFilters: state.courseFilters
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    requestCourses: (coursesHaveUpdated, courseFilters) => {
      dispatch(fetchCourses(coursesHaveUpdated, courseFilters))
    },
    addClasses: (rows) => {
      rows.every(function(row) {
        dispatch(addCourse(this.data()[2]))
      })
    },
    removeClasses: (rows) => {
      if (rows.data().length < 1) {
        dispatch(removeAllCourses())
      } else {
        rows.every(function(row) {
          dispatch(removeCourse(this.data()[2]))
        })
      }
    },
    changeCreditHours: (increment, minHours) => {
      dispatch(changeCreditHours(increment, minHours))
    }
  }
}

const CoursedSchedule = connect(
  mapStateToProps,
  mapDispatchToProps
)(ScheduleCalendar)

export default CoursedSchedule
