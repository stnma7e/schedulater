export const MIN_CREDIT_HOURS = 1
export const MAX_CREDIT_HOURS = 18

const creditHours = (state = {
    minHours: 12,
    maxHours: 15
}, action) => {
  switch (action.type) {
    case 'CHANGE_MIN_HOURS':
      var minHours = action.newHours;
      var maxHours = state.maxHours;
      if (maxHours < minHours) {
        maxHours = minHours
      }

      return Object.assign({}, state, {
        minHours: minHours,
        maxHours: maxHours
      })
    case 'CHANGE_MAX_HOURS':
      var minHours = state.minHours;
      var maxHours = action.newHours;
      if (minHours > maxHours) {
        minHours = maxHours
      }

      return Object.assign({}, state, {
        minHours: minHours,
        maxHours: maxHours
      })
    default:
      return state
  }
}

const courseFilters = (state = {
  coursesHaveUpdated: true,
  timeFilter: {
      start: "08:00:00 GMT-0400 (EDT)",
      end: "22:00:00 GMT-0400 (EDT)"
  },
  creditHours: {
    minHours: 12,
    maxHours: 15
  }
}, action) => {
  switch (action.type) {
    case 'TOGGLE_CLASSES_HAVE_UPDATED':
        return Object.assign({}, state, {
            classesHaveUpdated: !state.classesHaveUpdated
        })
    case 'CHANGE_START_TIME':
        return Object.assign({}, state, {
            timeFilter: {
                start: action.newTime,
                end: state.timeFilter.end
            }
        })
    case 'CHANGE_END_TIME':
        return Object.assign({}, state, {
            timeFilter: {
                start: state.timeFilter.end,
                end: action.newTime,
            }
        })
    case 'CHANGE_MIN_HOURS':
    case 'CHANGE_MAX_HOURS':
      return Object.assign({}, state, {
        creditHours: creditHours(state.creditHours, action)
      })
    default:
      return state
  }
}

export default courseFilters

export const toggleClassesHaveUpdated = () => {
    return {
        type: 'TOGGLE_CLASSES_HAVE_UPDATED'
    }
}

export const changeStartTime = (newTime) => {
    return {
        type: 'CHANGE_START_TIME',
        newTime
    }
}

export const changeEndTime = (newTime) => {
    return {
        type: 'CHANGE_END_TIME',
        newTime
    }
}

export const changeCreditHours = (isMinHours, newHours) => {
    if (isMinHours) {
      return {
        type: 'CHANGE_MIN_HOURS',
        newHours
      }
    } else {
      return {
        type: 'CHANGE_MAX_HOURS',
        newHours
      }
    }
}
