port module Main exposing (main)

import Debug exposing (log)
import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label, span, progress, p)
import Html.Attributes as HA exposing (placeholder, class, id, type_, value, disabled, title)
import Html.Events exposing (onClick, onInput)
import Browser
import Process
import Http
import Task
import Json.Decode exposing (string, list)
import Array exposing (Array)
import Dict exposing (Dict)

import Msg exposing (Msg(..))
import Course exposing (Course, Subject, Section, makeSched, decodeCourseData)
import Solve exposing (SolverState, solveCourses)
import CourseSelector exposing (CourseSelectorMsg(..), defaultCourseSelector)
import RenderFilter exposing (RenderFilterMsg(..), defaultRenderFilters, showTime)
import CourseOff exposing
    ( CourseOffData
    , CourseOffMsg(..)
    , defaultCourseOffData
    , getCourseOffSubjects
    )
import Modal exposing (modal)

flip f a b = f b a

main = Browser.element
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
    , startTime (\time -> RenderFilter <| NewStartTime time)
    , endTime (\time -> RenderFilter <| NewEndTime time)
    ]

init : () -> (Model, Cmd Msg)
init _ =
    let model =
            { calendar = CalendarData 0
            , subjects = []
            , renderFilters = defaultRenderFilters
            , courseOffData = defaultCourseOffData
            , courseSelector = defaultCourseSelector
            , addCourse = False
            , courses = Array.empty
            , courseChangeState = Modified
            , schedProgress = 0
            , showModal = False
            }
    in (model, Cmd.batch
        [ Cmd.map CourseOff getCourseOffSubjects
        ])

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
    , renderFilters : RenderFilter.RenderFilter
    , courseOffData : CourseOffData
    , courseSelector: CourseSelector.CourseSelector
    , addCourse: Bool
    , courses: Array Course
    , courseChangeState: ScheduleStatus
    , schedProgress: Int
    , showModal: Bool
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    RenderFilter msg1 ->
        let renderFilters = RenderFilter.dispatch msg1 model.renderFilters
        in { model
                | renderFilters = renderFilters
                , calendar = CalendarData 0
                }
           |> update (RenderCurrentSched Cmd.none)

    CourseOff msg1 ->
        let (courseOffData, cmd) = CourseOff.update msg1 model.courseOffData
        in ({model | courseOffData = courseOffData}, Cmd.map CourseOff cmd)

    CourseSelector msg1 ->
        let courseSelector1 = CourseSelector.update msg1 model.courseSelector
            newModel = {model | courseSelector = courseSelector1}
        in case msg1 of
            AddCourse _ ->
                ({ newModel | courseChangeState = Modified }, Cmd.none)
            SelectSubject subjectIdent -> newModel
                |> update (CourseOff <| GetSubjectCourses subjectIdent)
            otherwise -> (newModel, Cmd.none)

    Msg.GetSubjects -> model
        |> update (CourseOff CourseOff.GetSubjects)

    Msg.NewSubjects (Ok newSubjects) ->
        ({ model | subjects = newSubjects}, Cmd.none)

    Msg.NewSubjects (Err e) ->
        let _ = log "ERROR (NewSubjects)" <| Debug.toString e
        in (model, Cmd.none)

    GetScheds ->
        let newModel = { model | courseChangeState = Pending }
            newScheds = model.courseSelector.courses
                    |> Array.fromList
                    |> Solve.init
        in model |> update (SchedProgress newScheds)

    ContinueScheds currentScheds ->
        let newScheds = solveCourses currentScheds
        in model |> update (SchedProgress newScheds)

    SchedProgress currentScheds ->
        let newModel =
                { model
                | schedProgress = currentScheds.progress
                }
        in if currentScheds.progress == 100
            then let (newModel1, cmd) = newModel
                        |> update (RenderFilter <| NewCourses currentScheds.courseData)
                in ({ newModel1
                    | calendar = CalendarData 0
                    , courseChangeState = Received
                    , showModal = (Debug.log "shedCount" currentScheds.courseData.schedCount) <= 0
                    }
                , Cmd.batch [cmd, renderCurrentSched newModel])
            else (newModel, Process.sleep 0
                    |> Task.perform (always <| ContinueScheds currentScheds))

    NewScheds (Ok newScheds) ->
        let (newModel, cmd) = (model |> update (RenderFilter <| NewCourses newScheds))
        in ({ newModel
                | calendar = CalendarData 0
                , courseChangeState = Received
                }
            , Cmd.batch [cmd, renderCurrentSched newModel])

    NewScheds (Err e) ->
        let _ = log "ERROR (NewScheds)" <| Debug.toString e
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

    ToggleModal ->
        ({ model | showModal = not model.showModal }, Cmd.none)

renderCurrentSched : Model -> Cmd Msg
renderCurrentSched model = sched <| makeSched
    model.renderFilters.courseList
    model.calendar.schedIndex

view model =
    div [class "container"]
        [ div [class "columns"]
            [ div [class "column is-8"]
                [ debugInfo model

                , div [id "calendar"] []

                , nextPrevSchedButtons model

                , goButton model

                , Html.hr [] []

                , filters model
                ]
            , div [class "column"]
                <| courseSelector model
            ]
        , modal model.showModal ToggleModal
            [ div [ class "box"]
                [ p [ class "title is-4" ] [ text <| "That Didn't Work" ]
                , Html.hr [] []
                , p [] [ text <| "We couldn't make any schedules that work with these settings. Try adding some courses or changing the filters below." ]
                ]
            ]
        ]

debugInfo model =
    div [] <| List.map text
        [-- Debug.toString <| model.renderFilters
         -- Debug.toString <| model.requestFilters
        -- , Debug.toString <| model.courseSelector
        -- , Debug.toString <| Dict.size model.courseOffData.courses
        -- , Debug.toString <| model.renderFilters.lockedClasses
        -- , Debug.toString <| model.renderFilters.mustUseCourses
        ]

nextPrevSchedButtons model =
    div [class "columns"]
        [ div [class "column is-5"]
            [ button
                [ class <| "button is-primary is-outlined schedButton"
                , onClick DecrementSched
                , disabled <| model.calendar.schedIndex <= 0
                ] [text "Previous"]
            ]
        , div [class "column is-2"]
            [ div [ class "schedNumber" ]
                [ text <| String.fromInt <| model.calendar.schedIndex + 1 ]
            , div [ class "centering" ] [ text "of" ]
            , div [ class "schedNumber" ]
                [ text <| String.fromInt model.renderFilters.courseList.schedCount ]
            ]
        , div [class "column is-5"]
            [ button
                [ class <| "button is-primary is-outlined schedButton"
                , onClick IncrementSched
                , disabled <| model.calendar.schedIndex >=
                        model.renderFilters.courseList.schedCount
                ] [text "Next"]
            ]
        ]

goButton model =
    div []
        [ button
            [ class <| "button is-success is-outlined" ++ " " ++
                case model.courseChangeState of
                    Pending -> "is-loading"
                    otherwise -> ""
            , id "goButton"
            , onClick GetScheds
            , disabled <| case model.courseChangeState of
                Received -> True
                otherwise -> False
            ]
            [text "Go"]
        , progress
            [ class "progress is-success"
            , value <| String.fromInt model.schedProgress
            , HA.max "100"
            ]
            []
        ]

filters model =
    div []
        [ div [class "title"] [text "Customize"]
        , showFilter "Time"
            "What time do you want to start and finish your schedule?"
            <| div [class "columns"]
                [ showTimeFilter "Start: " "startTime" model.renderFilters.timeFilter.start
                , showTimeFilter "End: " "endTime" model.renderFilters.timeFilter.end
                ]

        , showFilter "Credits"
                "How many credit hours do you want to take?"
                <| div [class "columns"]
                    [ div [class "column"]
                        [ span [class "title is-6"] [text "Min: "]
                        , input [type_ "number"
                                , value <| String.fromInt model.renderFilters.creditFilter.min
                                , onInput (\min -> RenderFilter <| NewMinHours
                                    <| Maybe.withDefault model.renderFilters.creditFilter.min (String.toInt min))
                                ]
                                []
                        ]
                    , div [class "column"]
                        [ span [class "title is-6"] [text "Max: "]
                        , input [type_ "number"
                                , value <| String.fromInt model.renderFilters.creditFilter.max
                                , onInput (\max -> RenderFilter <| NewMaxHours
                                    <| Maybe.withDefault model.renderFilters.creditFilter.max (String.toInt max))
                                ]
                                []
                        ]
                    ]

        , showFilter "Instructor"
            "Are there any instructors that you don't want to take?"
            <| div [] []
        ]

courseSelector model =
    [ div
        [ onClick ShowCourseSelector
        , class <|"button is-primary schedButton" ++ " " ++
            if not model.addCourse
                then "is-outlined"
                else ""
        ]
        [text "Add courses"]
    , if model.addCourse
        then Html.map CourseSelector
            <| CourseSelector.view
                    model.courseSelector
                    model.courseOffData.subjects
                    model.courseOffData.courses
        else div [] []

    -- course tiles
    , div []
        [ div [class "tile is-ancestor"]
            [ div [class "tile is-parent is-vertical"]
                <| selectedCoursesTiles
                    model.courseSelector.courses
                    model.renderFilters
            ]
        ]
    ]

selectedCoursesTiles selectedCourses rf = selectedCourses
    |> List.map (\course ->
        let courseIdx = case Dict.get course.title rf.courseIndexMap of
                Just c -> c
                Nothing -> -1
        in div [class "box tile is-child"]
            [ text course.title
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
                , class <|"button courseButton is-outlined" ++ " " ++
                    case rf.previewCourse of
                        Nothing -> "is-white"
                        Just courseIdx2 ->
                            if courseIdx == courseIdx2
                                then "is-primary"
                                else "is-white"
                , title "Preview"
                ] [ text "👁" ]
            , div
                [ onClick (CourseSelector <| AddCourse course)
                , class <|"button is-danger courseButton Xbutton is-outlined"
                ]
                [text "X"]
            , selectedCrns rf courseIdx
            ])

selectedCrns rf courseIdx =
    div [] <| Maybe.withDefault []
        (flip Maybe.map (getCrnsFromCourseIdx rf courseIdx) (\crns ->
            [ div
                [ onClick (RenderFilter <| LockSection
                    <| Array.foldl (\x acc -> if acc > 0 then acc else x) -1 crns)
                , class <|"button courseButton" ++ " " ++
                    case rf.previewCourse of
                        Nothing -> "is-white"
                        Just courseIdx2 ->
                            if courseIdx == courseIdx2
                                then "is-primary"
                                else "is-white"
                , title "Preview"
                ] [ text "🔓" ]
            , text "Locked In Section #'s"
            , crnTiles crns
            ]))

getCrnsFromCourseIdx rf courseIdx =
    Dict.get courseIdx rf.lockedClasses
        |> Maybe.andThen (\classIdx -> Array.get courseIdx rf.courseList.courses
            |> Maybe.andThen (\course1 -> Array.get classIdx course1.classes
                |> Maybe.andThen (\sections -> Just (sections
                    |> Array.map (\section -> section.crn)))))

crnTiles crns =
    div [ class "tile is-ancestor" ]
        [ div [ class "tile is-parent" ]
            [ div []
                <| Array.toList
                <| Array.map (\crn ->
                        div [ class "tile is-parent" ]
                        [ div [ class "box tile is-child crnTile" ]
                            [ text <| String.fromInt crn ]
                        ]
                    ) crns
            ]
        ]

-- courseSelection : String -> List Subject -> List CourseTableData -> Html Msg
-- courseSelection subjectSearchString subjects selectedSubjectCourses =
--     div []
--         [ div [class "columns"]
--             [ div [class "column"]
--                 [input
--                     [placeholder "Filter"
--                     , onInput (\s -> RenderFilter <| SubjectSearchString s)
--                     ] []
--                 ]
--             , if List.length selectedSubjectCourses > 0
--                 then div [class "column"]
--                     [ span
--                         [ class "button is-primary is-outlined backButton"
--                         , onClick (RenderFilter DeselectCourseSubject)
--                         ] [ text "Back" ]
--                     ]
--                 else span [] []
--             ]
--
--         , div [class "subjectSelection"]
--             (if List.length selectedSubjectCourses < 1
--                 then subjects
--                     |> List.filter (String.contains
--                             <| String.toUpper subjectSearchString)
--                     |> List.map (\subject ->
--                             div [onClick (RenderFilter <| SelectCourseSubject subject)]
--                                 [text subject])
--                 else showSelectedSubjectCourses subjectSearchString selectedSubjectCourses
--             )
--
--         , Html.hr [] []
--         ]

-- showSelectedSubjectCourses subjectSearchString selectedSubjectCourses =
--     [ div []
--         [ table [class "table is-narrow is-hoverable courseSelectionTable"]
--             [ thead []
--                 [ td [] [text "Course Title"]
--                 , td [] [text "Course #"]
--                 , td [] [text "Credit Hours"]
--                 ]
--             , tbody []
--                 (selectedSubjectCourses
--                     |> List.filter (\course1 -> course1.title |> String.contains (String.toUpper subjectSearchString))
--                     |> List.map (\course1 ->
--                         tr  [ class "courseRow"
--                             , onClick (RequestFilter (AddCourse course1))
--                             ]
--
--                             [ td [] [text course1.title]
--                             , td [] [text course1.courseNum]
--                             , td [] [text course1.credits]
--                             ]
--                         )
--                     )
--             ]
--         ]
--     ]

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
