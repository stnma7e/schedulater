import {
    applyComboToClasses
} from "../components/schedule.js"

const courseSchedules = (state = {
    flat_courses: [],
    instructors: [],
    schedCount: 0,
    scheds: {
        currentValidScheds: [],
        allValidScheds: [],
        schedIndex: 0
    },
    schedFilters: {
        previewCourseIndex: null,
        lockedInList: []
    }
}, action) => {
    switch (action.type) {
        case 'RECEIVE_COURSES':
            // replace the current state with the network input
            return Object.assign({}, state, action.courses, {
                scheds: {
                    currentValidScheds: action.courses.scheds,
                    allValidScheds: action.courses.scheds.map((x) => {
                        return x
                    }),
                    schedIndex: 0
                },
                schedFilters: Object.assign({}, state.schedFilters, {
                    lockedInList: Array.apply(null,
                            Array(action.courses.flat_courses.length))
                        .map(Number.prototype.valueOf, 0)
                })
            })
        case 'SET_SCHED_INDEX':
            return Object.assign({}, state, {
                scheds: Object.assign({}, state.scheds, {
                    schedIndex: action.newIndex
                })
            })

        case 'SET_PREVIEW_COURSE':
            if (action.newIndex == null ||
                action.newIndex == state.schedFilters.previewCourseIndex)
            {
                return Object.assign({}, state, {
                    schedFilters: Object.assign({}, state.schedFilters, {
                        previewCourseIndex: null,
                    }),
                    scheds: getScheds(state)
                })
            }

            let totalSections = state.flat_courses[action.newIndex].classes.length
            let newCombos = [];
            for (var i = 1; i <= totalSections; i++) {
                let newCombo = Array.apply(null, Array(state.flat_courses.length)).map(Number.prototype.valueOf, 0)
                newCombo[action.newIndex] = i
                newCombos.push(newCombo)
            }

            return Object.assign({}, state, {
                schedFilters: Object.assign({}, state.schedFilters, {
                    previewCourseIndex: action.newIndex,
                }),
                scheds: Object.assign({}, state.scheds, {
                    currentValidScheds: newCombos,
                    schedIndex: 0
                })
            })

        case 'LOCK_COURSE_INDEX':
            let course_index, class_index = 0;
            for (var i = 0; i < state.flat_courses.length; i++) {
                for (var j = 0; j < state.flat_courses[i].classes.length; j++) {
                    // just use the first crn in the list because all we're worried about
                    // is the time that it occurs at, the actual CRN cane be manipulated
                    // later
                    if (state.flat_courses[i].classes[j][0].crn == action.crn) {
                        course_index = i
                        class_index = j + 1
                    }
                }
            }

            let newLockedIn = state.schedFilters.lockedInList.map((combo_index, idx) => {
                if (idx == course_index) {
                    if (combo_index == class_index) {
                        return 0
                    } else {
                        return class_index
                    }
                } else {
                    return combo_index
                }
            })

            console.log("lockedIn: " + newLockedIn)

            let newFilterState = Object.assign({}, state, {
                schedFilters: Object.assign({}, state.schedFilters, {
                    lockedInList: newLockedIn
                })
            })

            return Object.assign({}, newFilterState, {
                scheds: getScheds(newFilterState)
            })

        default:
            return state
    }
}
export default courseSchedules

const getScheds = (state) => {
    let validScheds = state.scheds.allValidScheds
        .filter((combo, idx) => {
            for (var i = 0; i < combo.length; i++) {
                if (state.schedFilters.lockedInList[i] == 0) {
                    continue
                }
                if (combo[i] != state.schedFilters.lockedInList[i]) {
                    return false
                }
            }

            return true
        })
    //console.log(validScheds)
    let currentSched = state.scheds.currentValidScheds[state.scheds.schedIndex];

    return Object.assign({}, state.scheds, {
        currentValidScheds: validScheds,
        schedIndex: Math.max(validScheds.findIndex((x) => x == currentSched), 0)
    })

}

export const lockCourseIndex = (course, crn) => {
    return {
        type: 'LOCK_COURSE_INDEX',
        course_title: course,
        crn
    }
}

export const setSchedIndex = (newIndex) => {
    return {
        type: "SET_SCHED_INDEX",
        newIndex
    }
}

export const setpreviewCourse = (courseIndex) => {
    return {
        type: "SET_PREVIEW_COURSE",
        newIndex: courseIndex
    }
}
