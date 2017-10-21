import { connect } from 'react-redux'
import ScheduleCalendar from './components/schedule'
import { addCourse, removeCourse, removeAllCourses, lockCourseIndex, setSchedIndex } from "./reducers/courses"
import fetchCourses from './actions/fetchCourses'

const mapStateToProps = (state) => {
  if (typeof state.courseSchedules == "undefined") {
    return {
      schedCount: 0,
      classes: [],
      combos:  [],
      schedIndex: 0,
      lockedIn: [],
      selectedCourses: Array.from(state.selectedCourses),
    }
  }

  return {
    schedCount:      state.courseSchedules.scheds.currentValidScheds.length,
    classes:         state.courseSchedules.flat_courses,
    combos:          state.courseSchedules.scheds.currentValidScheds,
    schedIndex:      state.courseSchedules.scheds.schedIndex,
    lockedIn:        state.courseSchedules.lockedIn,
    selectedCourses: Array.from(state.selectedCourses),
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    requestCourses: () => {
      dispatch(fetchCourses())
    },
    lockCourseIndex: (course, index) => {
      dispatch(lockCourseIndex(course, index))
    },
    setSchedIndex: (nextSched, schedIndex, schedCount) => {
        return () => {
            if (nextSched) {
                if (schedIndex < schedCount - 1) {
                  dispatch(setSchedIndex(schedIndex + 1))
                } else {
                  dispatch(setSchedIndex(0))
                }
            } else {
                if (schedIndex > 0) {
                  dispatch(setSchedIndex(schedIndex - 1))
                } else {
                  dispatch(setSchedIndex(schedCount - 1))
                }
            }
        }
    }
  }
}

const CoursedSchedule = connect(
  mapStateToProps,
  mapDispatchToProps
)(ScheduleCalendar)

export default CoursedSchedule
