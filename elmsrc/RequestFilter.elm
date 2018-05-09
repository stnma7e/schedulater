module RequestFilter exposing (..)

import Dict exposing (Dict)
import Json.Encode exposing (encode, object, list, string, int)

import Course

type alias TimeFilter =
    { start: Int
    , end: Int
    }

type alias CreditFilter =
    { min: Int
    , max: Int
    }

type alias InstructorFilter = Dict String String

type RequestFilterMsg
    = NewMaxHours Int
    | NewMinHours Int
    | AddCourse String

type alias ScheduleRequest =
    { courses: List String
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
                    { newCreditFilter | max = newHours
                                      , min = newMinHours
                    }
               }

        NewMinHours newMinHours ->
            let newHours = max 1 <| min 18 newMinHours
                newMaxHours = max requestFilters.creditFilter.max newHours
                newCreditFilter = requestFilters.creditFilter
            in { requestFilters | creditFilter =
                    { newCreditFilter | min = newHours
                                      , max = newMaxHours
                    }
               }

encodeScheduleRequest : ScheduleRequest -> String
encodeScheduleRequest sr = encode 0 <| object
    [ ("courses", list <| List.map string sr.courses)
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
    { courses = ["SURVEY OF CHEMISTRY I","SURVEY OF CHEMISTRY II","CHEM I CONCEPT DEVELOPMENT","PRINCIPLES OF CHEMISTRY I","PRINCIPLES OF CHEMISTRY II","INTERMEDIATE ORG CHEM LAB I","ORGANIC CHEMISTRY I","ORGANIC CHEMISTRY PROBLEMS I","ORGANIC CHEMISTRY II"]
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
