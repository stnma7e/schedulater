module CourseSelector exposing (..)

import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label, span)
import Html.Attributes exposing (placeholder, class, id, type_, value, disabled, title)
import Html.Events exposing (onClick, onInput)
import Dict exposing (..)

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
    }

defaultCourseSelector =
    { subjectSearchString = ""
    , selectedSubject = emptyIdent
    }

update : CourseSelectorMsg -> CourseSelector -> CourseSelector
update msg cs = case msg of
    SubjectSearchString f ->
        { cs | subjectSearchString = f }

    SelectSubject s ->
        { cs | selectedSubject = s, subjectSearchString = "" }

    DeselectSubject ->
        { cs | selectedSubject = emptyIdent, subjectSearchString = "" }

    otherwise -> cs

view : CourseSelector -> List SubjectIdent -> CourseDict -> Html CourseSelectorMsg
view cs subjects courses =
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
                -- show available subjects
                then subjects
                    |> List.filter (\subject -> String.contains
                            (String.toLower cs.subjectSearchString)
                            (String.toLower subject.userFacing))
                    |> List.map (\subject ->
                            div [onClick (SelectSubject subject)]
                                [text subject.userFacing])

                -- show subject's courses
                else let selectedSubjectCourses = courses
                            |> Dict.filter (\(subCmp, _) _ ->
                                cs.selectedSubject == cmp2Ident subCmp)
                            |> values
                    in showSelectedSubjectCourses
                            cs.subjectSearchString
                            selectedSubjectCourses
            )

        , Html.hr [] []
        ]

showSelectedSubjectCourses courseSearchString selectedSubjectCourses =
    [ div []
        [ table [class "table is-narrow is-hoverable courseSelectionTable"]
            [ thead []
                [ td [] [text "Course Title"]
                , td [] [text "Course #"]
                , td [] [text "Credit Hours"]
                ]
            , tbody []
                (selectedSubjectCourses
                    |> List.filter (\course1 -> String.toLower course1.title
                        |> String.contains (String.toLower courseSearchString))
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
