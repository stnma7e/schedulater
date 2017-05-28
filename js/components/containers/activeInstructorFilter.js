import { connect } from 'react-redux'
import { toggleInstructor } from '../../actions'
import { InstructorFilter } from '../instructor.js'

const mapStateToProps = (state) => {
  return {
    instructors: state.instructorMap.instructors,
    courses: state.instructorMap.courses
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    handleInstructorClick: (instructor) => {
      dispatch(toggleInstructor(instructor.name))
    }
  }
}

const ActiveInstructorFilter = connect(
  mapStateToProps,
  mapDispatchToProps
)(InstructorFilter)

export default ActiveInstructorFilter
