port module Main exposing (main)

import Debug exposing (log)
import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label)
import Html.Attributes exposing (placeholder, class, id, type_)
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
        , requestFilters = defaultBody
        , renderFilters = defaultRenderFilters
        , addCourse = False
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
    , requestFilters : ScheduleRequest
    , renderFilters : RenderFilter
    , addCourse: Bool
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
        in ({model | requestFilters = requestFilters}, Cmd.none)

    RenderFilter msg ->
        let renderFilters = RenderFilter.update msg model.renderFilters
            cmd = case msg of
                SelectCourseSubject sub ->
                    getCourses sub
                otherwise -> Cmd.none
        in {model | renderFilters = renderFilters
                  , calendar = CalendarData 0
           }
            |> update (RenderCurrentSched cmd)

    GetSubjects -> (model, getSubjects)

    GetScheds -> (model, getScheds model)

    NewSubjects (Ok newSubjects) ->
        ({ model | subjects = newSubjects}, Cmd.none)

    NewSubjects (Err e) ->
        let _ = log "ERROR (NewSubjects)" <| toString e
        in (model, Cmd.none)

    NewScheds (Ok newScheds) ->
        let (newModel, cmd) = (model |> update (RenderFilter <| NewCourses newScheds))
        in ({newModel | calendar = CalendarData 0},
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
    div []
        [ div [class "columns"]
            [ div [class "column is-8"]
                [ div [id "calendar"] []

                , div [] [button [onClick GetScheds] [text "Get Scheds"]]
                , button [class "schedButton", onClick DecrementSched] [text "Dec Sched"]
                , button [class "schedButton", onClick IncrementSched] [text "Inc Sched"]
                , creditHours (DecMaxHours, IncMaxHours) "max"
                , creditHours (DecMinHours, IncMinHours) "min"

                , Html.br [] []
                , Html.br [] []

                , div [] <| List.map (\x -> x |> toString |> text)
                    [ toString <| model.calendar.schedIndex
                    , toString <| model.renderFilters.selectedSubject
                    , toString <| model.renderFilters.courseList.schedCount
                    , toString <| model.renderFilters.lockedClasses
                    , toString <| model.renderFilters.mustUseCourses
                    ]
                ]
            , div [class "column"]
                [ button [class "schedButton", onClick ShowCourseSelector] [text "Show courses"]
                , Html.br [] []
                , Html.br [] []
                , if model.addCourse
                    then courseSelection model.renderFilters.subjectSearchString model.subjects model.renderFilters.selectedSubjectCourses
                    else div [] []
                , div []
                    [ div [class "tile is-ancestor"]
                        [ div [class "tile is-parent is-vertical"]
                           (selectedCoursesTiles model.requestFilters.courses)
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
--    |> reduceListToN 5
--    |> List.map (\courses -> div [class "tile is-parent"] (courses
        |> List.map (\course -> div [class "box tile is-child"]
            [ text course
            , Html.br [] []
            , label [class "checkbox"]
                [ input [ type_ "checkbox"
                        , onClick (RenderFilter <| MustUseCourse course)
                        ] []
                , text "Must use"
                ]
            ]) -- ))


courseSelection : String -> List Subject -> List CourseTableData -> Html Msg
courseSelection subjectSearchString subjects selectedSubjectCourses =
    div []
        [ input [placeholder "Course Subject" , onInput (\s -> RenderFilter <| SubjectSearchString s)] []

        , div [class "subjectSelection"]
            (if List.length selectedSubjectCourses < 1
                then subjects
                    |> List.filter (String.contains <| String.toUpper subjectSearchString)
                    |> List.map (\subject -> div [onClick (RenderFilter <| SelectCourseSubject subject)] [text subject])
                else showSelectedSubjectCourses subjectSearchString selectedSubjectCourses
            )
        ]

showSelectedSubjectCourses : String -> List CourseTableData -> List (Html Msg)
showSelectedSubjectCourses subjectSearchString selectedSubjectCourses =
    [ div [ class "backButton"
          , onClick (RenderFilter DeselectCourseSubject)
          ]
        [ text <| "Back" ]
    , div [class "columns"]
        [ div [class "column is-6"] [text "Course Title"]
        , div [class "column is-2"] [text "Course #"]
        , div [class "column is-3"] [text "Credit Hours"]
        ]
    , div []
        (selectedSubjectCourses
            |> List.filter (\course -> course.title |> String.contains (String.toUpper subjectSearchString))
            |> List.map (\course ->
                div [ class "columns"
                    , onClick (RequestFilter (AddCourse course.title))
                    ]
                    [ div [class "column is-6"] [text <| course.title]
                    , div [class "column is-2"] [text <| course.courseNum]
                    , div [class "column is-3"] [text <| course.credits]
                    ]))

    ]
