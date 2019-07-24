module RequestFilter exposing (..)

import Debug exposing (log)
import Dict exposing (Dict)
import Maybe exposing (andThen)
import Json.Encode exposing (encode, object, list, string, int)

import Course exposing (..)
import Combos exposing (..)
import ClassTimes exposing (StartEndTime)

type alias TimeFilter = StartEndTime

type alias CreditFilter =
    { min: Int
    , max: Int
    }

type alias InstructorFilter = Dict String String

type RequestFilterMsg
    = NewMaxHours Int
    | NewMinHours Int
    | NewStartTime String
    | NewEndTime String
    | AddCourse CourseIdent

type alias ScheduleRequest =
    { courses: List CourseIdent
    , timeFilter: TimeFilter
    , creditFilter: CreditFilter
    , instructorFilter: InstructorFilter
    }

update : RequestFilterMsg -> ScheduleRequest -> ScheduleRequest
update msg requestFilters =
    case msg of
        AddCourse course ->
                let newCourses = if List.member course requestFilters.courses
                        then List.filter ((/=) course) requestFilters.courses
                        else course :: requestFilters.courses
                in { requestFilters | courses = newCourses }

        NewMaxHours newMaxHours ->
            let newHours = max 1 <| min 18 newMaxHours
                newMinHours = min requestFilters.creditFilter.min newHours
                newCreditFilter = requestFilters.creditFilter
            in { requestFilters | creditFilter =
                    { newCreditFilter
                        | max = newHours
                        , min = newMinHours
                    }
               }

        NewMinHours newMinHours ->
            let newHours = max 1 <| min 18 newMinHours
                newMaxHours = max requestFilters.creditFilter.max newHours
                newCreditFilter = requestFilters.creditFilter
            in { requestFilters | creditFilter =
                    { newCreditFilter
                        | min = newHours
                        , max = newMaxHours
                    }
               }

        NewStartTime time ->
            let oldTimeFilter = requestFilters.timeFilter
                newTimeFilter = case timeFromString time of
                    Just t -> { oldTimeFilter | start = t }
                    Nothing -> log "start time not parsed" oldTimeFilter
            in { requestFilters | timeFilter = newTimeFilter }

        NewEndTime time ->
            let oldTimeFilter = requestFilters.timeFilter
                newTimeFilter = case timeFromString time of
                    Just t -> { oldTimeFilter | end = t }
                    Nothing -> log "end time not parsed" oldTimeFilter
            in { requestFilters | timeFilter = newTimeFilter }

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
    in maybeTime |> andThen identity

encodeScheduleRequest : ScheduleRequest -> String
encodeScheduleRequest sr = encode 0 <| object
    [ ("courses", list string <| List.map (\s -> s.internal) sr.courses)
    , ("time_filter", object
        [ ("start", int sr.timeFilter.start)
        , ("end", int sr.timeFilter.end)
        ])
    , ("credit_filter", object
        [ ("min_hours", int sr.creditFilter.min)
        , ("max_hours", int sr.creditFilter.max)
        ])
    , ("instructor_filter", sr.instructorFilter
        |> Dict.map (\x y -> string y)
        |> Dict.toList
        |> object)
    ]

defaultBody =
    { courses = [] 
    , timeFilter =
        { start = 8 * 60
        , end = 19 * 60
        }
    , creditFilter =
        { min = 12
        , max = 15
        }
    , instructorFilter = Dict.empty
    }
