import {
    combineReducers
} from 'redux';
import instructorMap from './instructors.js';
import courseSchedules from './courses.js';
import scheduledCourses from './scheduledCourses.js';
import courseFilters from './courseFilters.js'

const scheduleApp = combineReducers({
    instructorMap,
    scheduledCourses,
    courseSchedules,
    courseFilters
});

export default scheduleApp