const creditHours = (state = {}, action) => {
  switch (action.type) {
    case 'INCREMENT_MIN_HOURS':
      var minHours = state.minHours + 1;
      var maxHours = state.maxHours;
      if (maxHours < minHours) {
        maxHours = minHours
      }

      return Object.assign({}, state, {
        minHours: minHours,
        maxHours: maxHours
      })
    case 'INCREMENT_MAX_HOURS':
      return Object.assign({}, state, {
        maxHours: state.maxHours + 1
      })
    case 'DECREMENT_MIN_HOURS':
      return Object.assign({}, state, {
        minHours: state.minHours - 1
      })
    case 'DECREMENT_MAX_HOURS':
      var maxHours = state.maxHours - 1;
      var minHours = state.minHours;
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
  creditHours: {
    minHours: 12,
    maxHours: 15
  }
}, action) => {
  switch (action.type) {
    case 'INCREMENT_MIN_HOURS':
    case 'INCREMENT_MAX_HOURS':
    case 'DECREMENT_MIN_HOURS':
    case 'DECREMENT_MAX_HOURS':
      return Object.assign({}, state, {
        creditHours: creditHours(state.creditHours, action)
      })
    default:
      return state
  }
}

export default courseFilters
