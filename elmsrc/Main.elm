port module Main exposing (main)

import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody)
import Html.Attributes exposing (placeholder, class)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (string, list)
import Array exposing (Array)

import Course exposing (..)
import Filter exposing (..)

main = Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

subscriptions model =
    Sub.none

init =
    let model =
        { courses  = CourseData 0 Array.empty Array.empty
        , calendar = CalendarData 0
        , subjects = []
        , coursesErr = ""
        , selectedSubject = ""
        , subjectSearchString = ""
        , selectedSubjectCourses = []
        , addedCourses = []
        , requestFilters = defaultBody
        , maxHours = 0
        , minHours = 0
        }
    in (model, Cmd.batch
        [ getScheds model
        , getSubjects
        ]
    )

type alias CalendarData =
    { schedIndex : Int
    }

type alias Model =
    { courses : CourseData
    , calendar : CalendarData
    , subjects : List Subject
    , coursesErr : String
    , subjectSearchString : String
    , selectedSubject : Subject
    , selectedSubjectCourses: List CourseTableData
    , addedCourses : List String
    , requestFilters : ScheduleRequest
    , maxHours : Int
    , minHours : Int
    }

type Msg
    = Filter FilterMsg
    | SubjectSearchString String
    | GetSubjects
    | GetScheds
    | NewSubjects (Result Http.Error (List Subject))
    | NewScheds (Result Http.Error (CourseData))
    | IncrementSched
    | DecrementSched
    | RenderCurrentSched
    | SelectCourseSubject String
    | NewCourses (Result Http.Error (List CourseTableData))

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Filter msg ->
            let requestFilters = updateFilter msg model.requestFilters
            in ({model | requestFilters = requestFilters}, Cmd.none)

        GetSubjects ->
            (model, getSubjects)

        GetScheds ->
            (model, getScheds model)

        NewSubjects (Ok newSubjects) ->
            ({ model | subjects = newSubjects}, Cmd.none)

        NewSubjects (Err e) ->
            ({model | subjects = [toString e]}, Cmd.none)

        NewScheds (Ok newScheds) ->
            {model | courses = newScheds, calendar = CalendarData 0}
                |> update RenderCurrentSched

        NewScheds (Err e) ->
            ({model | coursesErr = toString e}, Cmd.none)

        RenderCurrentSched ->
            (model, sched (makeSched model.courses model.calendar.schedIndex))

        IncrementSched ->
            let newSchedIndex = min (model.courses.schedCount - 1) (model.calendar.schedIndex + 1)
            in {model | calendar = CalendarData newSchedIndex}
                |> update RenderCurrentSched

        DecrementSched ->
            let newSchedIndex = max 0 (model.calendar.schedIndex - 1)
            in {model | calendar = CalendarData newSchedIndex}
                |> update RenderCurrentSched

        SubjectSearchString f ->
            ({model | subjectSearchString = f}, Cmd.none)

        SelectCourseSubject s ->
            ({model | selectedSubject = s}, getCourses s)

        NewCourses (Ok data) ->
            ({model | selectedSubjectCourses = data}, Cmd.none)

        NewCourses (Err _) ->
            ({model | coursesErr = toString e}, Cmd.none)


view model =
  div []
    [ div [] [button [onClick GetScheds] [text "Get Scheds"]]
    , button [class "schedButton", onClick DecrementSched] [text "Dec Sched"]
    , button [class "schedButton", onClick IncrementSched] [text "Inc Sched"]
    , creditHours (DecMaxHours, IncMaxHours) "max"
    , creditHours (DecMinHours, IncMinHours) "min"
    , div [] [input [placeholder "Course Subject", onInput SubjectSearchString] []]
    , div [] <| List.map (\x -> x |> toString |> text)
        [ toString <| model.calendar.schedIndex
        , "err: " ++ (toString <| model.coursesErr)
        , toString <| model.requestFilters
        , toString <| model.minHours
        , toString <| model.selectedSubject
        , toString <| model.requestFilters.courses
        ]
    , div [class "columns"] (model.requestFilters.courses
        |> List.map (\course -> div [class "selectedCourseBox column"] [text course]))
    , div []
        [ div [class "subjectSelection"] (model.subjects
            |> List.filter (String.contains <| String.toUpper model.subjectSearchString)
            |> List.map (\subject -> div [onClick (SelectCourseSubject subject)] [text subject]))
        , div [class "subjectSelection"]
            [table []
                [ thead []
                    [ td [] [text "Course Title"]
                    , td [] [text "Course #"]
                    , td [] [text "Credit Hours"]
                    ]
                , tbody []
                    (model.selectedSubjectCourses
                        |> List.map (\course -> tr [onClick (Filter (AddCourse course.title))]
                            [ td [] [text <| toString <| course.title]
                            , td [] [text <| toString <| course.courseNum]
                            , td [] [text <| toString <| course.credits]
                            ]))
                ]
            ]
        ]
    ]

getSubjects : Cmd Msg
getSubjects = Http.send NewSubjects (Http.get "/subjects" (list string))

getCourses : Subject -> Cmd Msg
getCourses sub = Http.send NewCourses (Http.get ("/courses/" ++ sub) (list decodeCourseTableData))

getScheds : Model -> Cmd Msg
getScheds model = Http.send NewScheds (Http.post "/courses"
    (Http.stringBody "application/json"
        <| encodeScheduleRequest model.requestFilters)
    decodeCourseData)

port sched : List (String, Section) -> Cmd a

creditHours : (FilterMsg, FilterMsg) -> String -> Html Msg
creditHours (dec, inc) minmax = div []
    [ button [class "schedButton", onClick (Filter dec)] [text <| "Dec" ++ minmax]
    , button [class "schedButton", onClick (Filter inc)] [text <| "Inc" ++ minmax]
    ]
