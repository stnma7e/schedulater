import { connect } from 'react-redux'
import ScheduleCalendar from '../schedule.js'
import { fetchCourses, addCourse, removeCourse, removeAllCourses } from "../../actions";

const mapStateToProps = (state) => {
  if (  state.courseRequests.length < 1
     || typeof state.courseRequests[state.courseRequests.length-1].courses == "undefined"
  ) {
    return {
      schedule: { "courses": { "schedule": []}},
      schedCount: { "courses": { "sched_count": 0}},
      courses: Array.from(state.currentCourses),
      instructors: state.instructorMap
    }
  }

  return {
    schedule:   state.courseRequests[state.courseRequests.length-1],
    schedCount: state.courseRequests[state.courseRequests.length-1],
    courses: Array.from(state.currentCourses),
    instructors: state.instructorMap
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
    }
  }
}

const CoursedSchedule = connect(
  mapStateToProps,
  mapDispatchToProps
)(ScheduleCalendar)

export default CoursedSchedule
