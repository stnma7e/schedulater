module Solve exposing (..)

import Array exposing (Array)
import Result
import Maybe exposing (withDefault, andThen)
import Debug exposing (log)

import RenderFilter exposing (..)
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
    , courseData: CourseData
    , progress: Int
    }

init : Array Course -> SolverState
init courses =
    let initialCombo = Array.repeat (Array.length courses) 0
        maxCombo = log "max" <| Array.map (\c -> Array.length c.classes) courses
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
                        , courseData = if filterCombo courses nextCombos.current
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

filterCombo : Array Course -> Combo -> Bool
filterCombo courses combo =
    let sections = getComboSections courses combo
                |> List.filter isJust
                |> sequence
                |> withDefault []
        noTimeCollision = not <| checkTimesCollide sections
    in noTimeCollision

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
