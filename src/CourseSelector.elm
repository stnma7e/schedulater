module CourseSelector exposing (..)

import Html exposing (Html, button, div, text, input, table, tr, td, thead, tbody, label, span)
import Html.Attributes exposing (placeholder, class, id, type_, value, disabled, title)
import Html.Events exposing (onClick, onInput)

import Course exposing (..)

type CourseSelectorMsg
    = SubjectSearchString String
    | DeselectSubject
    | SelectSubject SubjectIdent

type alias CourseSelector =
    { subjectSearchString: String
    , selectedSubject: SubjectIdent
    , selectedSubjectCourses: List CourseIdent
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
            , if List.length cs.selectedSubjectCourses > 0
                then div [class "column"]
                    [ span
                        [ class "button is-primary is-outlined backButton"
                        , onClick DeselectSubject
                        ] [ text "Back" ]
                    ]
                else span [] []
            ]

        , div [class "subjectSelection"]
            (if List.length cs.selectedSubjectCourses < 1
                then subjects
                    |> List.filter (\subject -> String.contains
                            (String.toLower cs.subjectSearchString)
                            (String.toLower subject.userFacing))
                    |> List.map (\subject ->
                            div [onClick (SelectSubject subject)]
                                [text subject.userFacing])
                else [] --showSelectedSubjectCourses cs.subjectSearchString cs.selectedSubjectCourses
            )

        , Html.hr [] []
        ]
