import { connect } from 'react-redux'
import { toggleClassesHaveUpdated, changeStartTime, changeEndTime } from '../../reducers/courseFilters'
import { addCourse, removeCourse, removeAllCourses } from '../../reducers/scheduledCourses'
import fetchCourses from '../../actions/fetchCourses'
import CourseSelector from '../courseSelector'

const mapStateToProps = (state) => {
    return {}
}

const mapDispatchToProps = (dispatch) => {
  return {
    toggleClassesHaveUpdated: () => {
      dispatch(toggleClassesHaveUpdated())
    },
    requestCourses: () => {
        dispatch(fetchCourses())
    },
    changeStartTime: (newTime) => {
        dispatch(changeStartTime(newTime))
    },
    changeEndTime: (newTime) => {
        dispatch(changeEndTime(newTime))
    },
    addClasses: (rows) => {
      dispatch(toggleClassesHaveUpdated())
      rows.every(function(row) {
        dispatch(addCourse(this.data()[2]))
      })
      dispatch(fetchCourses())
    },
    removeClasses: (rows) => {
      if (typeof rows == "undefined") {
        console.error("rows were undefined")
        return
      }

      dispatch(toggleClassesHaveUpdated())
      if (rows.data().length < 1) {
        dispatch(removeAllCourses())
      } else {
        rows.every(function(row) {
          dispatch(removeCourse(this.data()[2]))
        })
      }
      dispatch(fetchCourses())
    },
  }
}

const CourseSelectorContainer = connect(
  mapStateToProps,
  mapDispatchToProps
)(CourseSelector)

export default CourseSelectorContainer
