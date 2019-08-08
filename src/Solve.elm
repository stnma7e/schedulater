module Solve exposing (..)

import Array exposing (Array)
import Result
import Maybe exposing (withDefault, andThen)
import Debug exposing (log)

import RequestFilter exposing (..)
import Course exposing (..)
import Combos exposing (..)
import ClassTimes exposing (..)

flip f a b = f b a

sequence : List (Maybe a) -> Maybe (List a)
sequence mss = case mss of
    [] -> Just []
    (m::ms) -> m |> andThen
        (\x -> sequence ms |> andThen
            (\xs -> Just (x::xs)))

isJust x = case x of
    Nothing -> False
    Just _ -> True

type alias SolverState =
    { combos: Combos
    , scheduleRequest: ScheduleRequest
    , courseData: CourseData
    , progress: Int
    }

init : ScheduleRequest -> Array Course -> SolverState
init sr courses =
    let filteredCourses = Array.filter (\c -> List.member c sr.courses) courses
        currentCombo = Array.repeat (Array.length filteredCourses) 0
        initialCombo = Array.repeat (Array.length filteredCourses) 0
        maxCombo = log "max" <| Array.map (\c -> c.classes |> Array.length) filteredCourses
        combos = Combos initialCombo maxCombo
    in { combos = combos
        , scheduleRequest = sr
        , courseData = CourseData 0 courses (Array.fromList [])
        , progress = 0
        }

solveCourses : SolverState -> SolverState
solveCourses state =
    let sr = state.scheduleRequest
        combos = state.combos
        courseData = state.courseData
        courses = courseData.courses
        valid = courseData.combos
        in case incrementCombo combos of
            Nothing ->
                { state
                | progress = 100
                , courseData =
                    { courseData
                    | schedCount = (Array.length valid)
                    }
                }
            Just nextCombos ->
                let newState =
                        { state
                        | combos = nextCombos
                        , courseData = if filterCombo sr courses nextCombos.current
                            then
                                { courseData
                                | combos = Array.push nextCombos.current valid
                                }
                            else courseData
                        }
                in if modBy 100 (currentCombo combos) == 0
                    then
                        { newState
                        | progress = (currentCombo combos) * 100 // (maxCombo combos.max)
                        }
                    else solveCourses newState

filterCombo : ScheduleRequest -> Array Course -> Combo -> Bool
filterCombo sr courses combo =
    let sections = getComboSections courses combo
                |> List.filter isJust
                |> sequence
                |> withDefault []
        validTimes = checkTimes combo sr.timeFilter sections
        noTimeCollision = not <| checkTimesCollide sections
        validCredits = checkCreditHours courses combo sr.creditFilter
    in validCredits && validTimes && noTimeCollision

checkTimes : Combo -> TimeFilter -> List Section -> Bool
checkTimes combo tf sections = sections
    |> List.map (\s -> timeRangeValid tf s.daytimes)
    |> List.foldl (&&) True

checkCreditHours : Array Course -> Combo -> CreditFilter -> Bool
checkCreditHours courses combo cf =
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

-- returns true if times collide
checkTimesCollide : List Section -> Bool
checkTimesCollide sections = case sections of
    [] -> False
    (section :: sx) ->
        let allClassTimes = List.map (\s -> s.daytimes) sx
        in checkTimeConflicts section.daytimes allClassTimes
            || checkTimesCollide sx

checkTimeConflicts : ClassTimes -> List ClassTimes -> Bool
checkTimeConflicts ct1 cts = cts
    |> List.map (\ct2 -> checkClassTimesCollide ct1 ct2)
    |> List.foldl (||) (False)

getComboSections : Array Course -> Combo -> List (Maybe Section)
getComboSections courses combo =
    let comboSections = flip Array.indexedMap combo
            (\courseIdx sectionIdx -> let course = Array.get courseIdx courses
                in getIthSectionOfCourse course sectionIdx)
    in Array.toList comboSections

getIthSectionOfCourse : Maybe Course -> ClassIndex -> Maybe Section
getIthSectionOfCourse c i = c
    |> andThen (\x -> Array.get (i - 1) x.classes) -- if i == -1, then we return Nothing
    |> andThen (Array.get 0)
