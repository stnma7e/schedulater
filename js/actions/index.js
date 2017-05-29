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

const fetchCourses = (coursesHaveUpdated, courseFilters) => {
  return function(dispatch) {
    dispatch(requestCourses(courseFilters));
    return (
      fetch('/courses', {
        method: 'POST',
        body: JSON.stringify(Object.assign({}, courseFilters, {
          courses: courseFilters.courses,
          instructor_filter: courseFilters.instructor_filter.courses.reduce((acc, cur, i) => {
            acc[cur.name] = cur.instructors.reduce((instructorList, instructorId) => {
              let instructor = courseFilters.instructor_filter.instructors[instructorId];
              if (!instructor.active) {
                instructorList.push(instructor.name)
              }
              return instructorList
            }, []);
            return acc;
          }, {})
        }))
      })
      .then(response => response.json())
      .then(json => {
        dispatch(receiveCourses(json));

        console.info("schedCount:", json.sched_count);

        if (json.sched_count < 1) {
          alert("There weren't any schedules that could be made from the options you selected. Maybe the minimum credit hours are set too high, or some filters are too restrictive.")
        }

        if (coursesHaveUpdated) {
          var instructors = [];
          var courses = [];
          var course_idx = 0;
          var ins_idx = 0;
          for (var course in json.instructors) {
            course_idx++,
            courses.push({
              name: course,
              instructors: []
            })
            for (var instructor in json.instructors[course]) {
              courses[course_idx-1].instructors.push(ins_idx);
              ins_idx++;
              instructors.push({
                name: json.instructors[course][instructor],
                active: true
              })
            }
          }

          dispatch(replaceCourses(courses));
          dispatch(replaceInstructors(instructors));
        }
      })
    )
  }
}

export { toggleInstructor, addInstructor, fetchCourses, addCourse, removeCourse, changeCreditHours }
