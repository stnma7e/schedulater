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

solveCourses : ScheduleRequest -> Array Course -> CourseData
solveCourses sr courses =
    let currentCombo = Array.repeat (Array.length courses) 0
        initialCombo = Array.repeat (Array.length courses) 0
        maxCombo = log "max" <| Array.map (\c -> c.classes |> Array.length) courses
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
checkCombo s courses combo =
    let y = getComboSections courses combo
        x = withDefault True <| (y |> checkTimesCollide |> Maybe.map not)
        z = checkCreditHours courses combo 12 15
    in z && x

checkCreditHours : Array Course -> Combo -> Int -> Int -> Bool
checkCreditHours courses combo min max =
    let l_courses = Array.toList courses
        l_combo = Array.toList combo
        courseCredits = List.map2 (\course comboIndex ->
            if comboIndex > 0 then
                case String.toInt course.credits of
                    Just credit -> credit
                    Nothing -> 1000
            else 0) l_courses l_combo
        sum = List.foldl (+) 0 courseCredits
    in sum >= min && sum <= max

-- returns true if times collide
checkTimesCollide : List (Maybe Section) -> Maybe Bool
checkTimesCollide sections = case sections of
    [] -> Just False
    (section :: sx) ->
        let classTimes = section |> andThen (\s -> getClassTimes s.daytimes)
            allClassTimes = withDefault [] <| sequence
                <| List.map (andThen (\s -> getClassTimes s.daytimes))
                <| List.filter isJust sx
        in Maybe.map ((||) <| checkTimeConflicts classTimes allClassTimes)
            (checkTimesCollide sx)

checkTimeConflicts : Maybe ClassTimes -> List ClassTimes -> Bool
checkTimeConflicts ct cts = withDefault False <| (ct |> andThen (\ct1 ->
    Just <| List.foldl (||) (False)
        <| List.map (\ct2 -> checkClassTimesCollide ct1 ct2)
        cts))

getComboSections : Array Course -> Combo -> List (Maybe Section)
getComboSections courses combo =
    let comboSections = flip Array.indexedMap combo
            <| \i -> getIthSectionOfCourse <| Array.get i courses
    in Array.toList comboSections

getIthSectionOfCourse : Maybe Course -> ClassIndex -> Maybe Section
getIthSectionOfCourse c i = c
    |> andThen (\x -> Array.get (i - 1) x.classes)
    |> andThen (Array.get 0)

isJust x = case x of
    Nothing -> False
    Just _ -> True
