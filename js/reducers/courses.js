import { applyComboToClasses } from "../components/schedule.js"

const courseSchedules = (state = {
  sched_count: 0,
  flat_courses: [],
  scheds: {
    currentValidScheds: [],
    allValidScheds:     [],
  },
  instructors: [],
  lockedIn: []
}, action) => {
  switch (action.type) {
    case 'RECEIVE_COURSES':
      return Object.assign({}, action.courses, {
        scheds: {
          currentValidScheds: action.courses.scheds,
          allValidScheds:     action.courses.scheds.map((x) => { return x })
        },
        lockedIn: Array.apply(null, Array(action.courses.flat_courses.length)).map(Number.prototype.valueOf,0)
      })
    case 'LOCK_COURSE_INDEX':
      let course_index, class_index = 0;
      for (var i=0; i<state.flat_courses.length; i++) {
        for (var j=0; j<state.flat_courses[i].classes.length; j++) {
          if (state.flat_courses[i].classes[j].crn == action.crn) {
            course_index = i
            class_index = j + 1
          }
        }
      }

      let newLockedIn = state.lockedIn.map((combo_index, idx) => {
          if (idx == course_index) {
            if (combo_index == class_index) {
              return 0
            } else {
              return class_index
            }
          } else {
            return combo_index
          }
        })

      let newCurrentValidScheds = state.scheds.allValidScheds.filter((combo, idx) => {
            for (var i=0; i<combo.length; i++) {
              if (newLockedIn[i] == 0) {
                continue
              }
              if (combo[i] != newLockedIn[i]) {
                return false
              }
            }

            return true
          })

      return Object.assign({}, state, {
        scheds: {
          allValidScheds: state.scheds.allValidScheds,
          currentValidScheds: newCurrentValidScheds
        },
        lockedIn: newLockedIn
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
