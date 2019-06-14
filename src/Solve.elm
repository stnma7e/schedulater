module Solve exposing (..)

import Array exposing (..)
import Maybe exposing (andThen)
import Parser exposing ((|=), (|.), run, succeed, end, int, symbol)

import RequestFilter exposing (..)
import Course exposing (..)
import Combos exposing (..)

type alias ClassTime = String

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
checkCombo s a b = True

getCourseForCombo : Array Course -> Combo -> Maybe (Array Section)
getCourseForCombo courses combo =
    let comboSections = Array.indexedMap (\i -> getIthSectionOfCourse <| Array.get i courses) combo
        maybeComboSections = sequence (Array.toList comboSections)
    in maybeComboSections
        |> andThen (\sections -> if checkTimes sections
            then Maybe.map (Array.fromList) maybeComboSections
            else Nothing)

checkTimes : List Section -> Bool
checkTimes sections =
    let classTimes = List.map (\x -> "") sections
    in List.foldl (&&) True <| (flip List.map sections
        (\section -> checkTimeConflict section.daytimes classTimes))

checkTimeConflict : ClassTime -> List ClassTime -> Bool
checkTimeConflict ct cts = False

getIthSectionOfCourse : Maybe Course -> ClassIndex -> Maybe Section
getIthSectionOfCourse c i = Nothing

parseClassTime s = flip run s
    (time |. (symbol ",") |= time |. (symbol "|") |= days |. end)

time = int |= int |. (symbol ":") |= int |= int |. end

days = int
