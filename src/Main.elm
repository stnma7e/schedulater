port module Main exposing (main)

import Debug exposing (log)
import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label, span)
import Html.Attributes exposing (placeholder, class, id, type_, value, disabled, title)
import Html.Events exposing (onClick, onInput)
import Browser
import Http
import Json.Decode exposing (string, list)
import Array exposing (Array)
import Dict exposing (Dict)

import Course exposing (..)
import RequestFilter exposing (..)
import RenderFilter exposing (..)
import Combos exposing (..)
import Solve exposing (..)
import CourseOff exposing (..)

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
    , startTime (\time -> RequestFilter <| NewStartTime time)
    , endTime (\time -> RequestFilter <| NewEndTime time)
    ]

init : () -> (Model, Cmd Msg)
init _ =
    let model =
            { calendar = CalendarData 0
            , subjects = []
            , requestFilters = defaultBody
            , renderFilters = defaultRenderFilters
            , courseOffData = defaultCourseOffData
            , addCourse = False
            , courses = Array.empty
            , requestFilterStatus = Modified
            }
    in (model, Cmd.batch
        [ getScheds model
        , Cmd.map CourseOff getCourseOffSubjects
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
    , requestFilters : ScheduleRequest
    , renderFilters : RenderFilter
    , courseOffData : CourseOffData
    , addCourse: Bool
    , courses: Array Course
    , requestFilterStatus: ScheduleStatus
    }

type Msg
    = RequestFilter RequestFilterMsg
    | RenderFilter RenderFilterMsg
    | CourseOff CourseOffMsg
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
    RequestFilter msg1 ->
        let requestFilters = RequestFilter.update msg1 model.requestFilters
        in ({model
            | requestFilters = requestFilters
            , requestFilterStatus = Modified
            }, Cmd.none)

    RenderFilter msg1 ->
        let renderFilters = RenderFilter.dispatch msg1 model.renderFilters
            cmd = case msg1 of
                SelectCourseSubject subject -> getCourses subject
                otherwise -> Cmd.none
            (model1, cmd1) = case msg1 of
                SelectCourseSubject sub -> model
                    |> update (CourseOff <| GetSubjectCourses sub)
                otherwise -> (model, Cmd.none)
        in {model1 | renderFilters = renderFilters
                  , calendar = CalendarData 0
           } |> update (RenderCurrentSched (Cmd.batch [cmd, cmd1]))

    CourseOff msg1 ->
        let (courseOffData, cmd) = CourseOff.update msg1 model.courseOffData
        in ({model
            | courseOffData = courseOffData
            }, Cmd.map CourseOff cmd)

    GetSubjects -> -- (model, getSubjects)
        model |> update (CourseOff CourseOff.GetSubjects)

    NewSubjects (Ok newSubjects) ->
        ({ model | subjects = newSubjects}, Cmd.none)

    NewSubjects (Err e) ->
        let _ = log "ERROR (NewSubjects)" <| Debug.toString e
        in (model, Cmd.none)

    GetScheds -> ({ model | requestFilterStatus = Pending }, getScheds model)

    NewScheds (Ok newScheds) ->
        let newScheds1 = solveCourses model.requestFilters newScheds.courses
            (newModel, cmd) = (model |> update (RenderFilter <| NewCourses newScheds1))
        in ({ newModel
                | calendar = CalendarData 0
                , requestFilterStatus = Received
                }, Cmd.batch [cmd, renderCurrentSched newModel])

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

getSubjects : Cmd Msg
getSubjects = Http.get
    { url = "/subjects"
    , expect = Http.expectJson NewSubjects (list string)
    }

getCourses : Subject -> Cmd Msg
getCourses sub = Http.get
    { url = "/courses/" ++ sub
    , expect = Http.expectJson (\x -> RenderFilter <| NewSubjectCourseList x) (list decodeCourseTableData)
    }

getScheds : Model -> Cmd Msg
getScheds model = Http.post
    { url = "/courses"
    , body = Http.stringBody "application/json"
        <| encodeScheduleRequest model.requestFilters
    , expect = Http.expectJson NewScheds decodeCourseData
    }

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
        ]

debugInfo model =
    div [] <| List.map text
        [
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
    button
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

filters model =
    div []
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
                                , value <| String.fromInt model.requestFilters.creditFilter.min
                                , onInput (\min -> RequestFilter <| NewMinHours
                                    <| Maybe.withDefault model.requestFilters.creditFilter.min (String.toInt min))
                                ]
                                []
                        ]
                    , div [class "column"]
                        [ span [class "title is-6"] [text "Max: "]
                        , input [type_ "number"
                                , value <| String.fromInt model.requestFilters.creditFilter.max
                                , onInput (\max -> RequestFilter <| NewMaxHours
                                    <| Maybe.withDefault model.requestFilters.creditFilter.max (String.toInt max))
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
        then courseSelection
                model.renderFilters.subjectSearchString
                model.courseOffData.subjects
                <| Maybe.withDefault [] <| Dict.get
                    model.renderFilters.selectedSubject
                    model.courseOffData.subjectCourses
                -- model.renderFilters.selectedSubjectCourses
        else div [] []

    , div []
        [ div [class "tile is-ancestor"]
            [ div [class "tile is-parent is-vertical"]
               <| selectedCoursesTiles model.requestFilters.courses model.renderFilters
            ]
        ]
    ]

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
                [ onClick (RequestFilter <| AddCourse course)
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

courseSelection : String -> List Subject -> List CourseTableData -> Html Msg
courseSelection subjectSearchString subjects selectedSubjectCourses =
    div []
        [ div [class "columns"]
            [ div [class "column"]
                [input
                    [placeholder "Filter"
                    , onInput (\s -> RenderFilter <| SubjectSearchString s)
                    ] []
                ]
            , if List.length selectedSubjectCourses > 0
                then div [class "column"]
                    [ span
                        [ class "button is-primary is-outlined backButton"
                        , onClick (RenderFilter DeselectCourseSubject)
                        ] [ text "Back" ]
                    ]
                else span [] []
            ]

        , div [class "subjectSelection"]
            (if List.length selectedSubjectCourses < 1
                then subjects
                    |> List.filter (String.contains
                            <| String.toUpper subjectSearchString)
                    |> List.map (\subject ->
                            div [onClick (RenderFilter <| SelectCourseSubject subject)]
                                [text subject])
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
                    |> List.filter (\course1 -> course1.title |> String.contains (String.toUpper subjectSearchString))
                    |> List.map (\course1 ->
                        tr  [ class "courseRow"
                            , onClick (RequestFilter (AddCourse course1.title))
                            ]

                            [ td [] [text course1.title]
                            , td [] [text course1.courseNum]
                            , td [] [text course1.credits]
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
