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
        Just nextCombos -> if filterCombo sr courses combos.current
            then runComboAndSolve sr courses nextCombos (combos.current :: valid)
            else runComboAndSolve sr courses nextCombos valid

filterCombo : ScheduleRequest -> Array Course -> Combo -> Bool
filterCombo sr courses combo =
    let sections = getComboSections courses combo
        validTimes = checkTimes (withDefault []
            <| sequence <| List.filter isJust sections) combo sr.timeFilter
        noTimeCollision = withDefault True <|
                (sections |> checkTimesCollide |> Maybe.map not)
        validHours = checkCreditHours courses combo sr.creditFilter
    in noTimeCollision && validHours

checkTimes : List Section -> Combo -> TimeFilter -> Bool
checkTimes sections combo tf = List.foldl (||) False
    <| List.map (\s -> checkTimeRange tf s.daytimes) sections

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
checkTimesCollide : List (Maybe Section) -> Maybe Bool
checkTimesCollide sections = case sections of
    [] -> Just False
    (section :: sx) ->
        let classTimes = section |> andThen (\s -> Just s.daytimes)
            allClassTimes = withDefault [] <| sequence
                <| List.map (andThen (\s -> Just s.daytimes))
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
