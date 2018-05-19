port module Main exposing (main)

import Debug exposing (log)
import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label, span)
import Html.Attributes exposing (placeholder, class, id, type_, value, disabled, title)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (string, list)
import Array exposing (Array)
import Dict exposing (Dict)

import Course exposing (..)
import RequestFilter exposing (..)
import RenderFilter exposing (..)

main = Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

port sched : List (String, Section) -> Cmd a
port lockSection : (Int -> a) -> Sub a
port startTime : (String -> a) -> Sub a
port endTime : (String -> a) -> Sub a

subscriptions model = Sub.batch
    [ lockSection (\crn -> RenderFilter <| LockSection crn)
    , startTime (\time -> RequestFilter <| NewStartTime time)
    , endTime (\time -> RequestFilter <| NewEndTime time)
    ]

init =
    let model =
        { calendar = CalendarData 0
        , subjects = []
        , requestFilters = defaultBody
        , renderFilters = defaultRenderFilters
        , addCourse = False
        , requestFilterStatus = Modified
        }
    in (model, Cmd.batch
        [ getScheds model
        , getSubjects
        ]
    )

type alias CalendarData =
    { schedIndex : Int
    }

type ScheduleStatus
    = Received
    | Pending
    | Modified

type alias Model =
    { calendar : CalendarData
    , subjects : List Subject
    , requestFilters : ScheduleRequest
    , renderFilters : RenderFilter
    , addCourse: Bool
    , requestFilterStatus: ScheduleStatus
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
    | RenderCurrentSched (Cmd Msg)
    | ShowCourseSelector

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    RequestFilter msg ->
        let requestFilters = RequestFilter.update msg model.requestFilters
        in ({model
            | requestFilters = requestFilters
            , requestFilterStatus = Modified
            }, Cmd.none)

    RenderFilter msg ->
        let renderFilters = RenderFilter.dispatch msg model.renderFilters
            cmd = case msg of
                SelectCourseSubject subject ->
                    getCourses subject
                otherwise -> Cmd.none
        in {model | renderFilters = renderFilters
                  , calendar = CalendarData 0
           }
            |> update (RenderCurrentSched cmd)

    GetSubjects -> (model, getSubjects)

    GetScheds -> ({ model | requestFilterStatus = Pending }, getScheds model)

    NewSubjects (Ok newSubjects) ->
        ({ model | subjects = newSubjects}, Cmd.none)

    NewSubjects (Err e) ->
        let _ = log "ERROR (NewSubjects)" <| toString e
        in (model, Cmd.none)

    NewScheds (Ok newScheds) ->
        let (newModel, cmd) = (model |> update (RenderFilter <| NewCourses newScheds))
        in ({ newModel
            | calendar = CalendarData 0
            , requestFilterStatus = Received
            },
            Cmd.batch [cmd, renderCurrentSched newModel])

    NewScheds (Err e) ->
        let _ = log "ERROR (NewScheds)" <| toString e
        in (model, Cmd.none)

    RenderCurrentSched cmd -> (model, Cmd.batch [cmd, renderCurrentSched model])

    IncrementSched ->
        let newSchedIndex = min (model.renderFilters.courseList.schedCount - 1) (model.calendar.schedIndex + 1)
        in {model | calendar = CalendarData newSchedIndex}
            |> update (RenderCurrentSched Cmd.none)

    DecrementSched ->
        let newSchedIndex = max 0 (model.calendar.schedIndex - 1)
        in {model | calendar = CalendarData newSchedIndex}
            |> update (RenderCurrentSched Cmd.none)

    ShowCourseSelector ->
        ({model | addCourse = not model.addCourse}, Cmd.none)


view model =
    div [class "container"]
        [ div [class "columns"]
            [ div [class "column is-8"]
                [ div [] <| List.map (\x -> x |> toString |> text)
                    [ toString <| model.calendar.schedIndex
                    , toString <| model.renderFilters.selectedSubject
                    , toString <| model.renderFilters.courseList.schedCount
                    , toString <| model.renderFilters.lockedClasses
                    , toString <| model.renderFilters.mustUseCourses
                    ]

                , div [id "calendar"] []

                , div [class "columns"]
                    [ div [class "column"]
                        [ div
                            [ class "button is-primary is-outlined schedButton"
                            , onClick DecrementSched
                            ]
                            [text "Previous"]
                        ]
                    , div [class "column"]
                        [ div
                            [ class "button is-primary is-outlined schedButton"
                            , onClick IncrementSched
                            ]
                            [text "Next"]
                        ]
                    ]
                , button
                    [ class <| "button is-success is-outlined" ++ " " ++
                        case model.requestFilterStatus of
                            Pending -> "is-loading"
                            otherwise -> ""
                    , id "goButton"
                    , onClick GetScheds
                    , disabled <| case model.requestFilterStatus of
                        Received -> True
                        otherwise -> False
                    ]
                    [text "Go"]

                , Html.hr [] []

                , div []
                    [ div [class "title"] [text "Customize"]
                    , showFilter "Time"
                        "What time do you want to start and finish your schedule?"
                        <| div [class "columns"]
                            [ showTimeFilter "Start: " "startTime" model.requestFilters.timeFilter.start
                            , showTimeFilter "End: " "endTime" model.requestFilters.timeFilter.end
                            ]

                    , showFilter "Credits"
                            "How many credit hours do you want to take?"
                            <| div [class "columns"]
                                [ div [class "column"]
                                    [ span [class "title is-6"] [text "Min: "]
                                    , input [type_ "number"
                                            , value <| toString model.requestFilters.creditFilter.min
                                            , onInput (\min -> RequestFilter <| NewMinHours
                                                <| Result.withDefault model.requestFilters.creditFilter.min (String.toInt min))
                                            ]
                                            []
                                    ]
                                , div [class "column"]
                                    [ span [class "title is-6"] [text "Max: "]
                                    , input [type_ "number"
                                            , value <| toString model.requestFilters.creditFilter.max
                                            , onInput (\max -> RequestFilter <| NewMaxHours
                                                <| Result.withDefault model.requestFilters.creditFilter.max (String.toInt max))
                                            ]
                                            []
                                    ]
                                ]

                    , showFilter "Instructor"
                        "Are there any instructors that you don't want to take?"
                        <| div [] []
                    ]
                ]
            , div [class "column"]
                [ div
                    [ onClick ShowCourseSelector
                    , class <|"button is-primary schedButton" ++ " " ++
                        if not model.addCourse
                            then "is-outlined"
                            else ""
                    ]
                    [text "Add courses"]
                , if model.addCourse
                    then courseSelection model.renderFilters.subjectSearchString model.subjects model.renderFilters.selectedSubjectCourses
                    else div [] []

                , div []
                    [ div [class "tile is-ancestor"]
                        [ div [class "tile is-parent is-vertical"]
                           (selectedCoursesTiles model.requestFilters.courses model.renderFilters)
                        ]
                    ]
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

renderCurrentSched : Model -> Cmd Msg
renderCurrentSched model =
    sched <| makeSched
        model.renderFilters.courseList
        model.calendar.schedIndex

selectedCoursesTiles selectedCourses rf = selectedCourses
    |> List.map (\course ->
        let courseIdx = case Dict.get course rf.courseIndexMap of
            Just c -> c
            Nothing -> -1
        in div [class "box tile is-child"]
            [ text course
            , Html.br [] []
            , div
                [ onClick (RenderFilter <| MustUseCourse course)
                , class <|"button is-primary courseButton" ++ " " ++
                    if List.member courseIdx rf.mustUseCourses
                        then ""
                        else "is-outlined"
                ]
                [text "Must use"]
            , div
                [ onClick (RenderFilter <| PreviewCourse course)
                , class <|"button courseButton" ++ " " ++
                    case rf.previewCourse of
                        Nothing -> "is-white"
                        Just courseIdx2 ->
                            if courseIdx == courseIdx2
                                then "is-primary"
                                else "is-white"
                , title "Preview"
                ]
                [text "👁"]
            , Html.br [] []
            , Html.br [] []
            , div []
                [ text "Locked In Section #'s'"
                , Html.br [] []
                , let lockedCourse = Dict.get courseIdx rf.lockedClasses
                    |> Maybe.andThen (\classIdx -> Array.get courseIdx rf.courseList.courses
                        |> Maybe.andThen (\course -> Array.get classIdx course.classes
                            |> Maybe.andThen (\sections -> Just (sections
                                |> Array.map (\section -> section.crn)))))
                  in case lockedCourse of
                      Nothing -> text ""
                      Just classIdx -> div []
                          <| Array.toList
                          <| Array.map (\crn -> div [] [ text <| toString crn ] ) classIdx
                ]
            ])

courseSelection : String -> List Subject -> List CourseTableData -> Html Msg
courseSelection subjectSearchString subjects selectedSubjectCourses =
    div []
        [ div [class "columns"]
            [ div [class "column"] [input [placeholder "Filter" , onInput (\s -> RenderFilter <| SubjectSearchString s)] []]
            , div [class "column"]
                [ if List.length selectedSubjectCourses > 0
                    then span [ class "button is-primary is-outlined backButton"
                          , onClick (RenderFilter DeselectCourseSubject)
                          ]
                        [ text <| "Back" ]
                    else span [] []
                ]
            ]

        , div [class "subjectSelection"]
            (if List.length selectedSubjectCourses < 1
                then subjects
                    |> List.filter (String.contains <| String.toUpper subjectSearchString)
                    |> List.map (\subject -> div [onClick (RenderFilter <| SelectCourseSubject subject)] [text subject])
                else showSelectedSubjectCourses subjectSearchString selectedSubjectCourses
            )

        , Html.hr [] []
        ]

showSelectedSubjectCourses : String -> List CourseTableData -> List (Html Msg)
showSelectedSubjectCourses subjectSearchString selectedSubjectCourses =
    [ div []
        [ table [class "table is-narrow is-hoverable courseSelectionTable"]
            [ thead []
                [ td [] [text "Course Title"]
                , td [] [text "Course #"]
                , td [] [text "Credit Hours"]
                ]
            , tbody []
                (selectedSubjectCourses
                    |> List.filter (\course -> course.title |> String.contains (String.toUpper subjectSearchString))
                    |> List.map (\course ->
                        tr
                            [ class "courseRow"
                            , onClick (RequestFilter (AddCourse course.title))
                            ]

                            [ td [] [text <| course.title]
                            , td [] [text <| course.courseNum]
                            , td [] [text <| course.credits]
                            ]
                        )
                    )
            ]
        ]
    ]

showFilter : String -> String -> Html Msg -> Html Msg
showFilter title subtitle body =
    div [class "filterSection"]
        [ div []
            [ div [class "title is-4"] [text title]
            , div [class "subtitle is-6"] [text subtitle]
            ]
        , div [class "filterBody"] [body]
        ]

showTimeFilter : String -> String -> Int -> Html Msg
showTimeFilter label timePickerId time=
    div [class "column"]
        [ span [class "title is-6"] [text label]
        , input [ class "timePicker"
                , id timePickerId
                , value <| showTime time
                ]
                []
        ]
