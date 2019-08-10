module RenderFilter exposing (..)

import Debug exposing (log)
import Http
import Array exposing (Array)
import Dict exposing (Dict)
import Tuple exposing (first, second)

import Common exposing (flip, isJust, sequence)
import Course exposing
    ( CourseData
    , Course
    , CourseIndex
    , ClassIndex
    , CourseIdentCmp
    , findSection
    , findCourseIndex
    , applyCombo
    , cmp2Course
    , getCourseIdx
    )
import ClassTimes exposing(StartEndTime, timeRangeValid)
import Combos exposing (Combo)

type alias CreditFilter =
    { min: Int
    , max: Int
    }

type alias RenderFilter =
    { courseList: CourseData
    , originalCombos: Array Combo
    , lockedClasses: Dict CourseIdentCmp ClassIndex
    , labSections: Dict CourseIdentCmp ClassIndex
    , mustUseCourses: List CourseIdentCmp
    , previewCourse: Maybe CourseIdentCmp
    , creditFilter: CreditFilter
    , timeFilter: StartEndTime
    }

defaultRenderFilters =
    { courseList = CourseData 0 Array.empty Array.empty
    , originalCombos = Array.empty
    , lockedClasses = Dict.empty
    , labSections = Dict.empty
    , mustUseCourses = []
    , previewCourse = Nothing
    , creditFilter =
        { min = 12
        , max = 15
        }
    , timeFilter =
        { start = 8 * 60
        , end = 19 * 60
        }
    }

type RenderFilterMsg
    = LockSection Int
    | NewCourses CourseData
    | PreviewCourse CourseIdentCmp
    | MustUseCourse CourseIdentCmp
    | NewMaxHours Int
    | NewMinHours Int
    | NewStartTime String
    | NewEndTime String

-- dispatch receives events and decides whether the filter must be updated
--      if no change can be made (an error occured, etc)
--          then nothing is propagated to update
--          else update is called with the message to modify the filter
--      this will allow finer control over functions that must be called in many cases
--          i.e. updateCourses
dispatch : RenderFilterMsg -> RenderFilter -> RenderFilter
dispatch = update

update : RenderFilterMsg -> RenderFilter -> RenderFilter
update msg rf = case msg of
    NewCourses courses ->
        { rf
        | courseList = courses
        , originalCombos = courses.combos
        , lockedClasses = Dict.empty
        } |> updateCourses

    PreviewCourse courseIdent ->
        let newPreview = if Just courseIdent == rf.previewCourse
                then Nothing
                else Just courseIdent
        in { rf | previewCourse = newPreview }
            |> updateCourses

    MustUseCourse courseIdent ->
        let newMustUseCourses =
                if List.member courseIdent rf.mustUseCourses
                    then List.filter ((/=) courseIdent) rf.mustUseCourses
                    else courseIdent :: rf.mustUseCourses
        in { rf | mustUseCourses = newMustUseCourses }
            |> updateCourses

    -- only show schedules that include a certain crn
    LockSection crn -> case findSection crn rf.courseList.courses of
        Nothing -> rf
        Just (courseIdx, sectionIdx) ->
            let addingLabSection = isJust rf.previewCourse
                lockedList = if addingLabSection
                        then rf.labSections
                        else rf.lockedClasses
                newLocked = lockedList
                    |> Dict.update courseIdx (\currentIdx -> case currentIdx of
                        -- no section is locked in for that course yet: add it
                        Nothing -> Just sectionIdx
                        -- a section is locked: check to see if we are removing
                        Just sectionIdx2 -> if sectionIdx == sectionIdx2
                            then Nothing -- if the value is already present, delete it
                            else Just sectionIdx) -- else update to the new one
            in if addingLabSection
                    then { rf | lockedClasses = newLocked }
                    else { rf | labSections = newLocked }
                |> updateCourses

    NewMaxHours newMaxHours ->
        let newHours = max 1 <| min 18 newMaxHours
            newMinHours = min rf.creditFilter.min newHours
            newCreditFilter = rf.creditFilter
        in { rf | creditFilter =
                { newCreditFilter
                    | max = newHours
                    , min = newMinHours
                }
           } |> updateCourses

    NewMinHours newMinHours ->
        let newHours = max 1 <| min 18 newMinHours
            newMaxHours = max rf.creditFilter.max newHours
            newCreditFilter = rf.creditFilter
        in { rf | creditFilter =
                { newCreditFilter
                    | min = newHours
                    , max = newMaxHours
                }
           } |> updateCourses

    NewStartTime time ->
        let oldTimeFilter = rf.timeFilter
            newTimeFilter = case timeFromString time of
                Just t -> { oldTimeFilter | start = t }
                Nothing -> log "start time not parsed" oldTimeFilter
        in { rf | timeFilter = newTimeFilter }
            |> updateCourses

    NewEndTime time ->
        let oldTimeFilter = rf.timeFilter
            newTimeFilter = case timeFromString time of
                Just t -> { oldTimeFilter | end = t }
                Nothing -> log "end time not parsed" oldTimeFilter
        in { rf | timeFilter = newTimeFilter }
            |> updateCourses

updateCourses : RenderFilter -> RenderFilter
updateCourses rf =
    let courseList = rf.courseList
        newCombos = case rf.previewCourse of
            Just previewIdent ->
                let previewCourse = cmp2Course courseList.courses previewIdent
                    previewIdx = previewCourse
                        |> Maybe.map first
                        |> Maybe.withDefault -1
                    numSections = previewCourse
                        |> Maybe.map second
                        |> Maybe.andThen (\course -> Just <| Array.length course.lectures)
                        |> Maybe.withDefault 0
                    comboLength = Array.length courseList.courses
                in List.range 1 numSections
                    -- make a List of Combos where all the elements are set to
                    -- 0 except the course of interest, which has its element
                    -- set to the class index for each of its sections
                    |> List.map (\courseIdx ->
                        Array.initialize comboLength (\i ->
                            if i == previewIdx then courseIdx else 0))
                    |> Array.fromList
            Nothing -> -- there is no course being previewed now
                let filteredCombos = rf.originalCombos
                        |> Array.filter (filterTimes courseList.courses rf.timeFilter)
                        |> Array.filter (filterCreditHours courseList.courses rf.creditFilter)
                    newCombos1 = rf.lockedClasses
                        |> Dict.toList
                        |> flip List.foldl filteredCombos (\(courseIdent, sectionIdx) combos ->
                            combos |> Array.filter
                                (\combo ->
                                    let maybeSectionIdx = getCourseIdx courseList.courses courseIdent
                                            |> Maybe.andThen (\courseIdx -> Array.get courseIdx combo)
                                    in case maybeSectionIdx of
                                    -- index 0 is reserved for an unused course section
                                    -- so while lockedCourses uses the idicies of the array
                                    -- (starting at 0), this function needs to recognize how
                                    -- combinations are interpreted for rendering
                                    Just sectionIdx2 -> sectionIdx == sectionIdx2 - 1
                                    Nothing -> True
                                )
                            )
                in rf.mustUseCourses
                    |> flip List.foldl newCombos1 (\courseIdent combos ->
                        case cmp2Course courseList.courses courseIdent of
                            Just (courseIdx, _) -> combos
                                |> Array.filter (\combo -> case Array.get courseIdx combo of
                                    Just idx -> idx > 0
                                    Nothing -> False)
                            Nothing -> combos)
    in { rf | courseList =
            { courseList
            | schedCount = Array.length newCombos
            , combos = newCombos
            }
        }

filterTimes : Array Course -> StartEndTime -> Combo -> Bool
filterTimes courses timeFilter combo =
    let maybeClasses = sequence <| Array.toList <| Array.filter isJust <| applyCombo courses combo
    in case maybeClasses of
        Nothing -> False
        Just classes -> classes
            |> List.map (\class -> case Array.get 0 class of
                Just section1 -> timeRangeValid timeFilter section1.daytimes
                Nothing -> False)
            |> List.foldl (&&) True

filterCreditHours : Array Course -> CreditFilter -> Combo -> Bool
filterCreditHours courses cf combo =
    let l_courses = Array.toList courses
        l_combo = Array.toList combo
        courseCredits = List.map2 (\course comboIndex ->
            if comboIndex > 0 then
                case String.toInt course.credits of
                    Just credit -> credit
                    Nothing -> 1000
            else 0) l_courses l_combo
        sum = List.foldl (+) 0 courseCredits
    in sum >= cf.min && sum <= cf.max

showTime : Int -> String
showTime t =
    let mins = remainderBy 60 t
        minsStr = if mins < 10
            then "0" ++ String.fromInt mins
            else String.fromInt mins
    in String.fromInt (t // 60) ++ ":" ++ minsStr

timeFromString : String -> Maybe Int
timeFromString time =
    let timeList = String.split ":" time
        maybeHours = List.head timeList
        maybeMins = timeList |> List.tail |> Maybe.andThen List.head
        maybeTime = Maybe.map2 (\hours mins ->
            Maybe.map2 (\h m ->
                60*h + m)
            (String.toInt hours) (String.toInt mins))
            maybeHours maybeMins
    in maybeTime |> Maybe.andThen identity
