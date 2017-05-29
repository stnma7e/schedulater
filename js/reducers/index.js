import { combineReducers } from 'redux';
import instructorMap from './instructors.js';
import currentCourses, { courseRequests } from './courses.js';
import courseFilters from './courseFilters.js'

const scheduleApp = combineReducers({
  instructorMap,
  currentCourses,
  courseRequests,
  courseFilters
});

export default scheduleApp
