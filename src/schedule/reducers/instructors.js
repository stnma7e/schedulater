const instructor = (state = {}, action) => {
    switch (action.type) {
        case 'TOGGLE_INSTRUCTOR':
            if (state.name != action.name) {
                return state
            }

            return Object.assign({}, state, {
                active: !state.active
            })
        case 'ADD_INSTRUCTOR':
            return {
                name: action.name,
                active: true
            }
        default:
            return state
    }
}

const instructors = (state = [], action) => {
    switch (action.type) {
        case 'REPLACE_INSTRUCTORS':
            return action.instructors
        case 'TOGGLE_INSTRUCTOR':
            return state.map(i =>
                instructor(i, action)
            )
        case 'ADD_INSTRUCTOR':
            return [
                ...Array.from(state),
                instructor(undefined, action)
            ]
        default:
            return state
    }
}

const instructorMap = (state = {
    instructors: [],
    courses: []
}, action) => {
    switch (action.type) {
        case 'TOGGLE_INSTRUCTOR':
        case 'ADD_INSTRUCTOR':
        case 'REPLACE_INSTRUCTORS':
            return Object.assign({}, state, {
                instructors: instructors(state.instructors, action)
            })
        case 'REPLACE_COURSES':
            return Object.assign({}, state, {
                courses: action.courses
            });
        default:
            return state
    }
}

export default instructorMap

export const toggleInstructor = (name) => {
    return {
        type: 'TOGGLE_INSTRUCTOR',
        name
    }
}

export const addInstructor = (name) => {
    return {
        type: 'ADD_INSTRUCTOR',
        name
    }
}

export const replaceInstructors = (instructors) => {
    return {
        type: 'REPLACE_INSTRUCTORS',
        instructors
    }
}

export const replaceCourses = (courses) => {
    return {
        type: 'REPLACE_COURSES',
        courses
    }
}