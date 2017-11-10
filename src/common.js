export function CourseResponse(schedCount, instructors, flat_courses, scheds) {
    this.sched_count  = schedCount
    this.instructors  = instructors
    this.flat_courses = flat_courses
    this.scheds       = scheds
}

export function FlatCourse(subject, courseNum, credits, title, classes) {
    this.subject   = subject
    this.courseNum = courseNum
    this.credits   = credits
    this.title     = title
    this.classes   = classes
}

export function Class(crn, cap, remaining, instructor, daytimes) {
    this.crn        = crn
    this.cap        = cap
    this.remaining  = remaining
    this.instructor = instructor
    this.daytimes   = daytimes
}
