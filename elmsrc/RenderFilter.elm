module RenderFilter exposing (..)

import Http
import Array exposing (Array)

import Course exposing (..)

type alias RenderFilter =
    { courseList: CourseData
    , subjectSearchString: String
    , selectedSubject: Subject
    , selectedSubjectCourses: List CourseTableData
    , lockedClasses: List (Section, CourseIndex, ClassIndex)
    , err: String
    }

defaultRenderFilters =
    { courseList = CourseData 0 Array.empty Array.empty
    , subjectSearchString = ""
    , selectedSubject = ""
    , selectedSubjectCourses = []
    , lockedClasses = []
    , err = ""
    }

type RenderFilterMsg
    = SubjectSearchString String
    | SelectCourseSubject String
    | DeselectCourseSubject
    | LockSection Int
    | NewSubjectCourseList (Result Http.Error (List CourseTableData))
    | NewCourses CourseData

update : RenderFilterMsg -> RenderFilter -> RenderFilter
update msg sf = case msg of
    NewSubjectCourseList (Ok data) ->
        {sf | selectedSubjectCourses = data}

    NewSubjectCourseList (Err _) ->
        {sf | err = toString e}

    SubjectSearchString f ->
        {sf | subjectSearchString = f}

    SelectCourseSubject s ->
        {sf | selectedSubject = s}

    DeselectCourseSubject ->
        {sf | selectedSubject = "", selectedSubjectCourses = []}

    NewCourses courses ->
        {sf | courseList = courses}

    LockSection crn -> sf
