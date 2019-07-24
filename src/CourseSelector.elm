module CourseSelector exposing (..)

import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label, span)
import Html.Attributes exposing (placeholder, class, id, type_, value, disabled, title)
import Html.Events exposing (onClick, onInput)

import Course exposing (..)
import RequestFilter exposing (..)

type CourseSelectorMsg
    = SubjectSearchString String
    | DeselectSubject
    | SelectSubject SubjectIdent
    | CourseAdded Course

type alias CourseSelector =
    { subjectSearchString: String
    , selectedSubject: SubjectIdent
    , selectedSubjectCourses: List Course
    }

defaultCourseSelector =
    { subjectSearchString = ""
    , selectedSubject = emptyIdent
    , selectedSubjectCourses = []
    }

update : CourseSelectorMsg -> CourseSelector -> CourseSelector
update msg cs = case msg of
    SubjectSearchString f ->
        { cs | subjectSearchString = f }

    SelectSubject s ->
        { cs | selectedSubject = s, subjectSearchString = "" }

    DeselectSubject ->
        { cs
            | selectedSubject = emptyIdent
            , selectedSubjectCourses = []
        }

    otherwise -> cs

view : CourseSelector -> List SubjectIdent -> Html CourseSelectorMsg
view cs subjects =
    div []
        [ div [class "columns"]
            [ div [class "column"]
                [input
                    [placeholder "Filter"
                    , onInput (\s -> SubjectSearchString s)
                    ] []
                ]
            , if cs.selectedSubject /= emptyIdent
                then div [class "column"]
                    [ span
                        [ class "button is-primary is-outlined backButton"
                        , onClick DeselectSubject
                        ] [ text "Back" ]
                    ]
                else span [] []
            ]

        , div [class "subjectSelection"]
            (if cs.selectedSubject == emptyIdent
                then subjects
                    |> List.filter (\subject -> String.contains
                            (String.toLower cs.subjectSearchString)
                            (String.toLower subject.userFacing))
                    |> List.map (\subject ->
                            div [onClick (SelectSubject subject)]
                                [text subject.userFacing])
                else showSelectedSubjectCourses
                        cs.subjectSearchString
                        cs.selectedSubjectCourses
            )

        , Html.hr [] []
        ]

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
                            , onClick (CourseAdded course1)
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
