module RenderFilter exposing (..)

import Debug exposing (log)
import Http
import Array exposing (Array)
import Dict exposing (Dict)

import Course exposing (..)

type alias RenderFilter =
    { courseList: CourseData
    , originalCombos: Array Sched
    , subjectSearchString: String
    , selectedSubject: Subject
    , selectedSubjectCourses: List CourseTableData
    , lockedClasses: Dict CourseIndex ClassIndex
    , mustUseCourses: List CourseIndex
    , previewCourse: Maybe CourseIndex
    }

defaultRenderFilters =
    { courseList = CourseData 0 Array.empty Array.empty
    , originalCombos = Array.empty
    , subjectSearchString = ""
    , selectedSubject = ""
    , selectedSubjectCourses = []
    , lockedClasses = Dict.empty
    , mustUseCourses = []
    , previewCourse = Nothing
    }

type RenderFilterMsg
    = SubjectSearchString String
    | SelectCourseSubject String
    | DeselectCourseSubject
    | LockSection Int
    | NewSubjectCourseList (Result Http.Error (List CourseTableData))
    | NewCourses CourseData
    | PreviewCourse String
    | MustUseCourse String

update : RenderFilterMsg -> RenderFilter -> RenderFilter
update msg rf = case msg of
    NewSubjectCourseList (Ok data) ->
        {rf | selectedSubjectCourses = data}

    NewSubjectCourseList (Err e) ->
        let _ = log "ERROR (NewSubjectCourseList)" <| toString e
        in rf

    SubjectSearchString f ->
        {rf | subjectSearchString = f}

    SelectCourseSubject s ->
        {rf | selectedSubject = s, subjectSearchString = ""}

    DeselectCourseSubject ->
        {rf | selectedSubject = ""
            , selectedSubjectCourses = []}

    NewCourses courses ->
        {rf | courseList = courses
            , originalCombos = courses.combos
            , lockedClasses = Dict.empty}
            |> updateCourses

    PreviewCourse courseTitle ->
        case findCourse courseTitle rf.courseList of
            Nothing -> log "courseTitle not found for preview" rf
            Just courseIdx ->
                (if Just courseIdx == rf.previewCourse
                    then { rf | previewCourse = Nothing }
                    else { rf | previewCourse = Just courseIdx })
                |> updateCourses

    MustUseCourse courseTitle ->
        case findCourse courseTitle rf.courseList of
            Nothing -> log "courseTitle not found for mustUse" rf
            Just courseIdx ->
                let newMustUseCourses = if List.member courseIdx rf.mustUseCourses
                    then List.filter ((/=) courseIdx) rf.mustUseCourses
                    else courseIdx :: rf.mustUseCourses
                in { rf | mustUseCourses = newMustUseCourses }
                    |> updateCourses

    -- only show schedules that include a certain crn
    LockSection crn -> case findSection crn rf.courseList of
        Nothing -> rf
        Just (courseIdx, sectionIdx) ->
            let newLocked = rf.lockedClasses
                |> Dict.update courseIdx (\currentIdx -> case currentIdx of
                    -- no section is locked in for that course yet: add it
                    Nothing -> Just sectionIdx
                    -- a section is locked: check to see if we are removing
                    Just sectionIdx2 -> if sectionIdx == sectionIdx2
                        then Nothing -- if the value is already present, delete it
                        else Just sectionIdx) -- else update to the new one
            in { rf | lockedClasses = newLocked }
                |> updateCourses

updateCourses : RenderFilter -> RenderFilter
updateCourses rf =
    let newCombos = case rf.previewCourse of
        Just previewIdx ->
            let numSections = Array.get previewIdx rf.courseList.courses
                    |> Maybe.andThen (\course -> Just <| Array.length course.classes)
                    |> Maybe.withDefault 0
                comboLength = Array.length rf.courseList.courses
            in List.range 1 numSections
                |> List.map (\courseIdx -> Array.initialize comboLength (\i ->
                        if i == previewIdx then courseIdx else 0))
                |> Array.fromList
        otherwise -> -- there is no course being previewed now
            let newCombos1 = rf.lockedClasses
                    |> Dict.toList
                    |> flip List.foldl rf.originalCombos (\(courseIdx, sectionIdx) combos ->
                        combos |> Array.filter (\combo -> case Array.get courseIdx combo of
                            Just sectionIdx2 -> sectionIdx == sectionIdx2
                            Nothing -> False
                        ))
            in rf.mustUseCourses
                |> flip List.foldl newCombos1 (\courseIdx combos ->
                    combos |> Array.filter (\combo -> case Array.get courseIdx combo of
                        Just idx -> idx > 0
                        Nothing -> False
                ))
    in { rf | courseList =
            { schedCount = Array.length newCombos
            , courses = rf.courseList.courses
            , combos = newCombos
            }
        }
