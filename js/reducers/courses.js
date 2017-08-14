const courseSchedules = (state = {
  sched_count: 0,
  flat_courses: [],
  scheds: [],
  instructors: [],
  lockedIn: []
}, action) => {
  switch (action.type) {
    case 'RECEIVE_COURSES':
      return Object.assign({}, action.courses, {
        lockedIn: Array.apply(null, Array(action.courses.flat_courses.length)).map(Number.prototype.valueOf,0)
      })
    case 'LOCK_COURSE_INDEX':
      let indexi, indexj = 0;
      for (var i=0; i<state.flat_courses.length; i++) {
        for (var j=0; j<state.flat_courses[i].classes.length; j++) {
          if (state.flat_courses[i].classes[j].crn == action.crn) {
            indexi = i
            indexj = j + 1
          }
        }
      }

      return Object.assign({}, state, {
        lockedIn: state.lockedIn.map((combo_index, idx) => {
          if (idx == indexi) {
            return indexj
          } else {
            return combo_index
          }
        })
      })
    default:
      return state
  }
}

const selectedCourses = (state = new Set(), action) => {
  switch (action.type) {
    case 'REMOVE_ALL_COURSES':
      return new Set()
    case 'REMOVE_COURSE':
      return new Set(Array.from(state).filter(i => {
        return i != action.name
      }))
    case 'ADD_COURSE':
      return new Set(
        [
          ...Array.from(state),
          action.name
        ])
    default:
      return state
  }
}

export { selectedCourses, courseSchedules }
