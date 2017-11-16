import { connect } from 'react-redux'
import { setSelectedCourse } from '../../reducers/courses'

import CourseList from '../courseList'

const mapStateToProps = (state) => {
  if (typeof state.courseSchedules == "undefined") {
    return {
      courses: [],
      lockedIn: [],
    }
  }

  return {
    courses:  state.courseSchedules.flat_courses,
    lockedIn: state.courseSchedules.schedFilters.lockedIn.lockedInList,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    setSelectedCourse: (newIndex) => {
        dispatch(setSelectedCourse(newIndex))
    }
  }
}

const CourseListContainer = connect(
  mapStateToProps,
  mapDispatchToProps
)(CourseList)

export default CourseListContainer
