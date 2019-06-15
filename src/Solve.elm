module Solve exposing (..)

import Array exposing (Array)
import Maybe exposing (withDefault, andThen)

import RequestFilter exposing (..)
import Course exposing (..)
import Combos exposing (..)
import ClassTimes exposing (..)

sequence : List (Maybe a) -> Maybe (List a)
sequence mss = case mss of
    [] -> Just []
    (m::ms) -> m |> andThen
        (\x -> sequence ms |> andThen
            (\xs -> Just (x::xs)))

solveCourses : ScheduleRequest -> Array Course -> CourseData
solveCourses sr courses =
    let currentCombo = Array.repeat (Array.length courses) 0
        initialCombo = Array.repeat (Array.length courses) 0
        maxCombo = Array.map (\c -> c.classes |> Array.length) courses
        combos = Combos initialCombo maxCombo
    in runComboAndSolve sr courses combos []

runComboAndSolve : ScheduleRequest -> Array Course -> Combos -> List (Combo) -> CourseData
runComboAndSolve sr courses combos valid =
    case incrementCombo combos of
        Nothing -> CourseData (List.length valid) courses (Array.fromList valid)
        Just nextCombos -> if checkCombo sr courses combos.current
            then runComboAndSolve sr courses nextCombos (combos.current :: valid)
            else runComboAndSolve sr courses nextCombos valid

checkCombo : ScheduleRequest -> Array Course -> Combo -> Bool
checkCombo s a b = withDefault False (getComboSections a b
    |> andThen checkTimes)

getComboSections : Array Course -> Combo -> Maybe (List Section)
getComboSections courses combo =
    let comboSections = flip Array.indexedMap combo
        <| \i -> getIthSectionOfCourse <| Array.get i courses
    in sequence (Array.toList comboSections)

checkTimes : List Section -> Maybe Bool
checkTimes sections =
    if List.length sections == 0
        then Just True
        else let section = List.head sections
                 classTimes = sequence <| flip List.map sections (\s -> getClassTimes s.daytimes)
             in Maybe.map2 (&&)
                (checkTimeConflicts (section |> andThen (\s -> getClassTimes s.daytimes)) classTimes)
                (checkTimes (withDefault [] <| List.tail sections))

checkTimeConflicts : Maybe ClassTimes -> Maybe (List ClassTimes) -> Maybe Bool
checkTimeConflicts = Maybe.map2 (\ct1 cts1 -> List.foldl (&&) True
        <| List.map (\ct2 -> checkTimeConflict ct2 ct2) cts1)

checkTimeConflict : ClassTimes -> ClassTimes -> Bool
checkTimeConflict ct1 ct2 = False

getIthSectionOfCourse : Maybe Course -> ClassIndex -> Maybe Section
getIthSectionOfCourse c i = Nothing
