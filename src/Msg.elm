module Msg exposing (..)

import Http

import Course exposing (..)
import RequestFilter exposing (..)
import RenderFilter exposing (..)
import Solve exposing (..)
import CourseOff exposing (..)
import CourseSelector exposing (..)

type Msg
    = RequestFilter RequestFilterMsg
    | RenderFilter RenderFilterMsg
    | CourseOff CourseOffMsg
    | CourseSelector CourseSelectorMsg
    | GetSubjects
    | GetScheds
    | NewSubjects (Result Http.Error (List Subject))
    | NewScheds (Result Http.Error (CourseData))
    | IncrementSched
    | DecrementSched
    | RenderCurrentSched (Cmd Msg)
    | ShowCourseSelector
    | SchedProgress SolverState
    | ContinueScheds SolverState
    | ToggleModal
