import { replaceCourses, replaceInstructors } from '../reducers/instructors';
import { receiveCourses } from '../reducers/courses';

const fetchCourses = () => {
  return function(dispatch, getState) {

    let coursesHaveUpdated = getState().courseFilters.coursesHaveUpdated
    let courseFilters = {
        courses: [...Array.from(getState().selectedCourses)],
        time_filter: {
            // start: getState().courseFilters.timeFilter.start,
            // end: getState().courseFilters.timeFilter.end,
            start: $("#start_time").timepicker('getTime').toTimeString(),
            end: $("#end_time").timepicker('getTime').toTimeString()
        },
        credit_filter: {
            min_hours: getState().courseFilters.creditHours.minHours,
            max_hours: getState().courseFilters.creditHours.maxHours
        },
        instructor_filter: getState().instructorMap
    }

    return (
      /*
      fetch('/courses', {
        method: 'POST',
        body: '{"courses":["SURVEY OF CHEMISTRY I","SURVEY OF CHEMISTRY II","CHEM I CONCEPT DEVELOPMENT","PRINCIPLES OF CHEMISTRY I","PRINCIPLES OF CHEMISTRY II","INTERMEDIATE ORG CHEM LAB I","ORGANIC CHEMISTRY I","ORGANIC CHEMISTRY PROBLEMS I","ORGANIC CHEMISTRY II"],"time_filter":{"start":"08:00:00 GMT-0400 (EDT)","end":"19:00:00 GMT-0400 (EDT)"},"credit_filter":{"min_hours":12,"max_hours":15},"instructor_filter":{}}'
      })
      .then(response => response.json())
      .then(json => processInput(dispatch, json, true))
      */

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
      .then(json => processInput(dispatch, json, coursesHaveUpdated))
    )
  }
}

function processInput(dispatch, json, coursesHaveUpdated) {
  dispatch(receiveCourses(json));

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

  console.info("schedCount:", json.sched_count);
}

export default fetchCourses
