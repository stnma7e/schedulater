import {
    connect
} from 'react-redux'
import {
    setpreviewCourse
} from '../../reducers/courses'

import CourseList from '../courseList'

const mapStateToProps = (state) => {
    if (typeof state.courseSchedules == "undefined") {
        return {
            courses: [],
            lockedIn: [],
        }
    }

    return {
        courses: state.courseSchedules.flat_courses,
        lockedIn: state.courseSchedules.schedFilters.lockedInList,
    }
}

const mapDispatchToProps = (dispatch) => {
    return {
        setSelectedCourse: (newIndex) => {
            dispatch(setpreviewCourse(newIndex))
        }
    }
}

const CourseListContainer = connect(
    mapStateToProps,
    mapDispatchToProps
)(CourseList)

export default CourseListContainer
