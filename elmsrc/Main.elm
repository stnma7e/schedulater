port module Main exposing (main)

import Debug exposing (log)
import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody)
import Html.Attributes exposing (placeholder, class)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (string, list)
import Array exposing (Array)

import Course exposing (..)
import RequestFilter exposing (..)
import RenderFilter exposing (..)

main = Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

subscriptions model =
    lockSection (\crn -> RenderFilter <| LockSection crn)

init =
    let model =
        { calendar = CalendarData 0
        , subjects = []
        , coursesErr = ""
        , requestFilters = defaultBody
        , renderFilters = defaultRenderFilters
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
    { calendar : CalendarData
    , subjects : List Subject
    , coursesErr : String
    , requestFilters : ScheduleRequest
    , renderFilters : RenderFilter
    }

type Msg
    = RequestFilter RequestFilterMsg
    | RenderFilter RenderFilterMsg
    | GetSubjects
    | GetScheds
    | NewSubjects (Result Http.Error (List Subject))
    | NewScheds (Result Http.Error (CourseData))
    | IncrementSched
    | DecrementSched
    | RenderCurrentSched

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    RequestFilter msg ->
        let requestFilters = RequestFilter.update msg model.requestFilters
        in ({model | requestFilters = requestFilters}, Cmd.none)

    RenderFilter msg ->
        let renderFilters = RenderFilter.update msg model.renderFilters
            cmd = case msg of
                SelectCourseSubject sub ->
                    getCourses sub
                otherwise -> Cmd.none
        in ({model | renderFilters = renderFilters}, cmd)

    GetSubjects -> (model, getSubjects)

    GetScheds -> (model, getScheds model)

    NewSubjects (Ok newSubjects) ->
        ({ model | subjects = newSubjects}, Cmd.none)

    NewSubjects (Err e) ->
        ({model | subjects = [toString e]}, Cmd.none)

    NewScheds (Ok newScheds) ->
        let (newModel, cmd) = (model |> update (RenderFilter <| NewCourses newScheds))
        in ({newModel | calendar = CalendarData 0},
            Cmd.batch [cmd, renderCurrentSched newModel])

    NewScheds (Err e) ->
        ({model | coursesErr = toString e}, Cmd.none)

    RenderCurrentSched -> (model, renderCurrentSched model)

    IncrementSched ->
        let newSchedIndex = min (model.renderFilters.courseList.schedCount - 1) (model.calendar.schedIndex + 1)
        in {model | calendar = CalendarData newSchedIndex}
            |> update RenderCurrentSched

    DecrementSched ->
        let newSchedIndex = max 0 (model.calendar.schedIndex - 1)
        in {model | calendar = CalendarData newSchedIndex}
            |> update RenderCurrentSched


view model =
    div []
        [div [class "columns"]
            [div [class "column"]
                [div [] [button [onClick GetScheds] [text "Get Scheds"]]
                , button [class "schedButton", onClick DecrementSched] [text "Dec Sched"]
                , button [class "schedButton", onClick IncrementSched] [text "Inc Sched"]
                , creditHours (DecMaxHours, IncMaxHours) "max"
                , creditHours (DecMinHours, IncMinHours) "min"

                , div [] <| List.map (\x -> x |> toString |> text)
                    [ toString <| model.calendar.schedIndex
                    , "err: " ++ (toString <| model.coursesErr)
                    , toString <| model.requestFilters
                    , toString <| model.renderFilters.selectedSubject
                    , toString <| model.renderFilters.courseList.schedCount
                    ]
                ]
            , div [class "column"]
                [ div [] [input [placeholder "Course Subject", onInput (\s -> RenderFilter <| SubjectSearchString s)] []]
                , courseSelection model.renderFilters.subjectSearchString model.subjects model.renderFilters.selectedSubjectCourses
                ]
            ]
        , div []
            [div [class "tile is-ancestor"]
                [div [class "tile is-parent is-vertical"]
                   (selectedCoursesTiles model.requestFilters.courses)
                ]
            ]
        ]

getSubjects : Cmd Msg
getSubjects = Http.send NewSubjects (Http.get "/subjects" (list string))

getCourses : Subject -> Cmd Msg
getCourses sub = Http.send (\x -> RenderFilter <| NewSubjectCourseList x) (Http.get ("/courses/" ++ sub) (list decodeCourseTableData))

getScheds : Model -> Cmd Msg
getScheds model = Http.send NewScheds (Http.post "/courses"
    (Http.stringBody "application/json"
        <| encodeScheduleRequest model.requestFilters)
    decodeCourseData)

port sched : List (String, Section) -> Cmd a
port lockSection : (Int -> a) -> Sub a

renderCurrentSched : Model -> Cmd Msg
renderCurrentSched model =
    sched <| makeSched
        model.renderFilters.courseList
        model.calendar.schedIndex

creditHours : (RequestFilterMsg, RequestFilterMsg) -> String -> Html Msg
creditHours (dec, inc) minmax = div []
    [ button [class "schedButton", onClick (RequestFilter dec)] [text <| "Dec" ++ minmax]
    , button [class "schedButton", onClick (RequestFilter inc)] [text <| "Inc" ++ minmax]
    ]

reduceListToN : Int -> List a -> List (List a)
reduceListToN n xs = case xs of
    [] -> []
    otherwise -> (List.take n xs) :: reduceListToN n (List.drop n xs)

selectedCoursesTiles selectedCourses = selectedCourses
    |> reduceListToN 5
    |> List.map (\courses -> div [class "tile is-parent"] (courses
        |> List.map (\course -> div [class "box tile is-child"] [text course])))


courseSelection : String -> List Subject -> List CourseTableData -> Html Msg
courseSelection subjectSearchString subjects selectedSubjectCourses =
    if List.length selectedSubjectCourses > 0 then
        div [class "subjectSelection"]
            [ div
                [ class "backButton"
                , onClick (RenderFilter DeselectCourseSubject)
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
                        |> List.map (\course -> tr [onClick (RequestFilter (AddCourse course.title))]
                            [ td [] [text <| course.title]
                            , td [] [text <| course.courseNum]
                            , td [] [text <| course.credits]
                            ]))
                ]
            ]
    else
        div [class "subjectSelection"] (subjects
            |> List.filter (String.contains <| String.toUpper subjectSearchString)
            |> List.map (\subject -> div [onClick (RenderFilter <| SelectCourseSubject subject)] [text subject]))
