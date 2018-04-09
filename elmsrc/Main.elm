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
        , requestFilters = defaultBody
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
    , requestFilters : ScheduleRequest
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
    | DeselectCourseSubject

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

        DeselectCourseSubject ->
            ({model | selectedSubject = "", selectedSubjectCourses = []}, Cmd.none)


view model =
  div []
    [ div [class "column"]
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
            , toString <| model.selectedSubject
            ]
        ]
    , div [class "column"]
        [ div [class "tile is-ancestor"]
            [ div [class "tile is-parent is-vertical"]
                (selectedCoursesTiles model.requestFilters.courses)
            ]
        ]
    , courseSelection model.subjectSearchString model.subjects model.selectedSubjectCourses
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

reduceListToN : Int -> List a -> List (List a)
reduceListToN n xs = case xs of
    [] -> []
    otherwise -> (List.take n xs) :: reduceListToN n (List.drop n xs)

selectedCoursesTiles selectedCourses = selectedCourses
    |> reduceListToN 4
    |> List.map (\courses -> div [class "tile is-parent"] (courses
        |> List.map (\course -> div [class "box tile is-child"] [text course])))


courseSelection : String -> List Subject -> List CourseTableData -> Html Msg
courseSelection subjectSearchString subjects selectedSubjectCourses =
    if List.length selectedSubjectCourses > 0 then
        div [class "subjectSelection"]
            [ div
                [ class "backButton"
                , onClick DeselectCourseSubject
                ]
                [ text <| "Back" ]
            , table []
                [ thead []
                    [ td [] [text "Course Title"]
                    , td [] [text "Course #"]
                    , td [] [text "Credit Hours"]
                    ]
                , tbody []
                    (selectedSubjectCourses
                        |> List.map (\course -> tr [onClick (Filter (AddCourse course.title))]
                            [ td [] [text <| course.title]
                            , td [] [text <| course.courseNum]
                            , td [] [text <| course.credits]
                            ]))
                ]
            ]
    else
        div []
            [ div [class "subjectSelection"] (subjects
                |> List.filter (String.contains <| String.toUpper subjectSearchString)
                |> List.map (\subject -> div [onClick (SelectCourseSubject subject)] [text subject]))
            ]
