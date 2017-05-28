const courseRequests = (state = [], action) => {
  switch (action.type) {
    case 'REQUEST_COURSES':
      return [
        ...state,
        {
          isFetching: true,
          filters: action.filters
        }
      ]
    case 'RECEIVE_COURSES':
      return [
        ...state,
        {
          isFetching: false,
          courses: action.courses
        }
      ]
    default:
      return state
  }
}

const currentCourses = (state = new Set(), action) => {
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

export default currentCourses
export { courseRequests }
