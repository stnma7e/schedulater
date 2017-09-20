import ScheduleCalendar from '../schedule.js'
import { connect } from 'react-redux'
import { addCourse, removeCourse, removeAllCourses, lockCourseIndex, setSchedIndex } from "../../reducers/courses"
import { changeCreditHours, MAX_CREDIT_HOURS, MIN_CREDIT_HOURS } from "../../reducers/courseFilters";
import fetchCourses from '../../actions/fetchCourses.js'

const mapStateToProps = (state) => {
  if (typeof state.courseSchedules == "undefined") {
    return {
      schedCount: 0,
      classes: [],
      combos:  [],
      schedIndex: 0,
      lockedIn: [],
      selectedCourses: Array.from(state.selectedCourses),
      instructors:     state.instructorMap,
      courseFilters:   state.courseFilters
    }
  }

  return {
    schedCount:      state.courseSchedules.scheds.currentValidScheds.length,
    classes:         state.courseSchedules.flat_courses,
    combos:          state.courseSchedules.scheds.currentValidScheds,
    schedIndex:      state.courseSchedules.scheds.schedIndex,
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
    changeCreditHours: (maxHours, minHours) => {
        return (isSettingMinHours, event) => {
            if (event.target.value < MIN_CREDIT_HOURS || event.target.value > MAX_CREDIT_HOURS) {
              return
            }

            let increment = true

            if (isSettingMinHours) {
              if (minHours > event.target.value) {
                // minHours was decremented
                increment = false
              }
            } else {
              if (maxHours > event.target.value) {
                // minHours was decremented
                increment = false
              }
            }
            dispatch(changeCreditHours(increment, isSettingMinHours))
        }
    },
    lockCourseIndex: (course, index) => {
      dispatch(lockCourseIndex(course, index))
    },
    setSchedIndex: (newIndex) => {
      dispatch(setSchedIndex(newIndex))
    }
  }
}

const CoursedSchedule = connect(
  mapStateToProps,
  mapDispatchToProps
)(ScheduleCalendar)

export default CoursedSchedule
