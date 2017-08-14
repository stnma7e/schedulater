import ScheduleCalendar from '../schedule.js'
import { connect } from 'react-redux'
import { addCourse, removeCourse, removeAllCourses, changeCreditHours, lockCourseIndex } from "../../actions";
import fetchCourses from '../../actions/fetchCourses.js'

const mapStateToProps = (state) => {
  if (typeof state.courseSchedules == "undefined") {
    return {
      schedCount: 0,
      classes: [],
      combos:  [],
      lockedIn: [],
      selectedCourses: Array.from(state.selectedCourses),
      instructors:     state.instructorMap,
      courseFilters:   state.courseFilters
    }
  }

  return {
    schedCount:      state.courseSchedules.sched_count,
    classes:         state.courseSchedules.flat_courses,
    combos:          state.courseSchedules.scheds,
    lockedIn:        state.courseSchedules.lockedIn,
    selectedCourses: Array.from(state.selectedCourses),
    instructors:     state.instructorMap,
    courseFilters:   state.courseFilters
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
    },
    lockCourseIndex: (course, index) => {
      dispatch(lockCourseIndex(course, index))
    }
  }
}

const CoursedSchedule = connect(
  mapStateToProps,
  mapDispatchToProps
)(ScheduleCalendar)

export default CoursedSchedule
