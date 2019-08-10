module Msg exposing (..)

import Http

import Course exposing (..)
import RenderFilter exposing (..)
import Solve exposing (..)
import CourseOff exposing (..)
import CourseSelector exposing (..)

type Msg
    = RenderFilter RenderFilterMsg
    | CourseOff CourseOffMsg
    | CourseSelector CourseSelectorMsg
    | GetSubjects
    | GetScheds
    | IncrementSched
    | DecrementSched
    | RenderCurrentSched (Cmd Msg)
    | ShowCourseSelector
    | SchedProgress SolverState
    | ContinueScheds SolverState
    | ToggleModal
