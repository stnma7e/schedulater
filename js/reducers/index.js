import { combineReducers } from 'redux';
import instructorMap from './instructors.js';
import currentCourses, { courseRequests } from './courses.js';

const scheduleApp = combineReducers({
  instructorMap,
  currentCourses,
  courseRequests,
});

export default scheduleApp
