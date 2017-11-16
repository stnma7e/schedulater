const scheduledCourses = (state = new Set(), action) => {
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
export default scheduledCourses

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
