import { applyComboToClasses } from "../components/schedule.js"

const courseSchedules = (state = {
  flat_courses: [],
  instructors: [],
  sched_count: 0,
  scheds: {
    currentValidScheds: [],
    allValidScheds:     [],
    schedIndex: 0
  },
  schedFilters: {
      selectedCourse: (x) => {return true},
      lockedIn: {
            validScheds: (x) => {return true},
            lockedInList: []
      }
  }
}, action) => {
    switch (action.type) {
        case 'RECEIVE_COURSES':
        // replace the current state with the network input
            return Object.assign({}, state, action.courses, {
                scheds: {
                    currentValidScheds: action.courses.scheds,
                    allValidScheds:     action.courses.scheds.map((x) => { return x }),
                    schedIndex: 0
                },
                schedFilters: Object.assign({}, state.schedFilters, {
                    lockedIn: Object.assign({}, state.schedFilters.lockedIn, {
                        lockedInList: Array.apply(null,
                            Array(action.courses.flat_courses.length))
                            .map(Number.prototype.valueOf,0)
                    })
                })
            })
        case 'SET_SCHED_INDEX':
            return Object.assign({}, state, {
                scheds: Object.assign({}, state.scheds, {
                    schedIndex: action.newIndex
                })
            })

        // one of the filters to our schedules has been changed
        // re-evaluate currentValidScheds
        case 'SET_SELECTED_COURSE':
        case 'LOCK_COURSE_INDEX':
            filters = filterScheds(state, action)
            let validScheds = state.scheds.allValidScheds
                .filter(filters.selectedCourse)
                .filter(filters.lockedIn.validScheds)
            console.log(validScheds)
            let currentSched = state.scheds.currentValidScheds[state.scheds.schedIndex];

            return Object.assign({}, state, {
                schedFilters: filters,
                scheds: Object.assign({}, state.scheds, {
                    currentValidScheds: validScheds,
                    schedIndex: Math.max(validScheds.findIndex((x) => x == currentSched), 0)
                })
            })
        default:
            return state
    }
}

const filterScheds = (state, action) => {
  switch (action.type) {
    case "SET_SELECTED_COURSE":
        console.log(action.newIndex)
        if (action.newIndex == null) {
            return Object.assign({}, state.schedFilters, {
                selectedCourse: (x) => { return true }
            })
        }

        return Object.assign({}, state.schedFilters, {
            selectedCourse: (combo) => {
                return combo[action.newIndex] > 0
            }
        })
    case 'LOCK_COURSE_INDEX':
      let course_index, class_index = 0;
      for (var i = 0; i < state.flat_courses.length; i++) {
        for (var j = 0; j < state.flat_courses[i].classes.length; j++) {
          // just use the first crn in the list because all we're worried about
          // is the time that it occurs at, the actual CRN cane be manipulated
          // later
          if (state.flat_courses[i].classes[j][0].crn == action.crn) {
            course_index = i
            class_index = j + 1
          }
        }
      }

      let newLockedIn = state.schedFilters.lockedIn.lockedInList.map((combo_index, idx) => {
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

    console.log("NLL: " + newLockedIn)

      return Object.assign({}, state.schedFilters, {
        lockedIn: {
            lockedInList: newLockedIn,
            validScheds: (combo, idx) => {
                for (var i = 0; i < combo.length; i++) {
                    if (newLockedIn[i] == 0) {
                        continue
                    }
                    if (combo[i] != newLockedIn[i]) {
                        return false
                    }
                }

                return true
            }
        }
      })
    default:
      return state.schedFilters
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

export const addCourse = (name) => {
  return {
    type: 'ADD_COURSE',
    name
  }
}

export const removeCourse = (name) => {
  return {
    type: 'REMOVE_COURSE',
    name
  }
}

export const removeAllCourses = () => {
  return {
    type: 'REMOVE_ALL_COURSES',
  }
}

export const receiveCourses = (courses) => {
  return {
    type: 'RECEIVE_COURSES',
    courses
  }
}

export const lockCourseIndex = (course, crn) => {
  return {
    type: 'LOCK_COURSE_INDEX',
    course_title: course,
    crn
  }
}

export const setSchedIndex = (newIndex) => {
  return {
    type: "SET_SCHED_INDEX",
    newIndex
  }
}

export const setSelectedCourse = (courseIndex) => {
    return {
        type: "SET_SELECTED_COURSE",
        newIndex: courseIndex
    }
}
