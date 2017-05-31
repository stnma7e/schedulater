const toggleInstructor = (name) => {
  return {
    type: 'TOGGLE_INSTRUCTOR',
    name
  }
}

const addInstructor = (name) => {
  return {
    type: 'ADD_INSTRUCTOR',
    name
  }
}

const replaceInstructors = (instructors) => {
  return {
    type: 'REPLACE_INSTRUCTORS',
    instructors
  }
}

const replaceCourses = (courses) => {
  return {
    type: 'REPLACE_COURSES',
    courses
  }
}

const addCourse = (name) => {
  return {
    type: 'ADD_COURSE',
    name
  }
}

const removeCourse = (name) => {
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

const requestCourses = (courseFilters) => {
  return {
    type: 'REQUEST_COURSES',
    courseFilters
  }
}

const receiveCourses = (courses) => {
  return {
    type: 'RECEIVE_COURSES',
    courses
  }
}

const changeCreditHours = (increment, minHours) => {
  if (increment) {
    if (minHours) {
      return {
        type: 'INCREMENT_MIN_HOURS'
      }
    } else {
      return {
        type: 'INCREMENT_MAX_HOURS'
      }
    }
  } else {
    if (minHours) {
      return {
        type: 'DECREMENT_MIN_HOURS'
      }
    } else {
      return {
        type: 'DECREMENT_MAX_HOURS'
      }
    }
  }
}

export { toggleInstructor, addInstructor, addCourse, removeCourse, changeCreditHours, requestCourses, receiveCourses, replaceInstructors, replaceCourses }
