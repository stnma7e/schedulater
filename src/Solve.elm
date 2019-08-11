module Solve exposing (..)

import Array exposing (Array)
import Result
import Maybe exposing (withDefault, andThen)
import Debug exposing (log)
import Tuple exposing (second)

import Common exposing (flip, sequence, isJust)
import RenderFilter exposing (..)
import Course exposing (CourseData, Course, Section, ClassCombo(..), applyCombo)
import Combos exposing (..)
import ClassTimes exposing (hasTimeConflicts)

type alias SolverState =
    { combos: Combos
    , courseData: CourseData
    , progress: Int
    }

init : Array Course -> SolverState
init courses =
    let initialCombo = Array.repeat (Array.length courses) 0
        maxCombo = courses
                |> Array.toList
                |> List.concatMap (\c -> [Array.length c.lectures])
                |> Array.fromList
                |> Debug.log "max"
        combos = Combos initialCombo maxCombo
    in { combos = combos
        , courseData = CourseData 0 courses (Array.fromList [])
        , progress = 0
        }

solveCourses : SolverState -> SolverState
solveCourses state =
    let combos = state.combos
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
                        , courseData = if comboValid courses nextCombos.current
                            then
                                { courseData
                                | combos = Array.push nextCombos.current valid
                                }
                            else courseData
                        }
                in if modBy 500 (currentCombo nextCombos) == 0
                    then
                        { newState
                        | progress = (currentCombo nextCombos) * 100 // (maxCombo nextCombos.max)
                        }
                    else solveCourses newState

comboValid : Array Course -> Combo -> Bool
comboValid courses combo =
    let lectureSections = applyCombo courses (Lecture combo)
            |> Array.filter isJust
            |> Array.toList
            |> sequence |> Maybe.withDefault []
            |> List.map (\x -> second x |> Array.get 0)
            |> sequence |> Maybe.withDefault []
        sections = lectureSections
    in not <| List.isEmpty sections || doTimesCollide sections

-- returns true if times collide
doTimesCollide : List Section -> Bool
doTimesCollide sections = case sections of
    [] -> False
    (section :: sx) ->
        let allClassTimes = List.map (\s -> s.daytimes) sx
        in List.isEmpty section.daytimes
            || hasTimeConflicts section.daytimes allClassTimes
            || doTimesCollide sx
