import {
    connect
} from 'react-redux'
import ScheduleCalendar from './components/schedule'
import {
    addCourse,
    removeCourse,
    removeAllCourses,
    lockCourseIndex,
    setSchedIndex
} from "./reducers/courses"
import fetchCourses from './actions/fetchCourses'

const mapStateToProps = (state) => {
    return {
        schedCount: state.courseSchedules.scheds.currentValidScheds.length,
        schedIndex: state.courseSchedules.scheds.schedIndex,
        courses: state.courseSchedules.flat_courses,
        combos: state.courseSchedules.scheds.currentValidScheds,
        lockedIn: state.courseSchedules.schedFilters.lockedInList,
        previewCourseIndex: state.courseSchedules.schedFilters.previewCourseIndex
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
