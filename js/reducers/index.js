import { combineReducers } from 'redux';
import instructorMap from './instructors.js';
import { selectedCourses, courseSchedules } from './courses.js';
import courseFilters from './courseFilters.js'

const scheduleApp = combineReducers({
  instructorMap,
  selectedCourses,
  courseSchedules,
  courseFilters
});

export default scheduleApp
