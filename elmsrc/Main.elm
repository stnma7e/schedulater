port module Main exposing (main)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Http
import Types exposing (..)
import Json.Decode exposing (string, list)
import Array exposing (Array)
import Maybe exposing (withDefault, andThen)

main = Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

subscriptions model =
    Sub.none

init = (Model (CourseData 0 Array.empty Array.empty) (CalendarData 0) [] "", Cmd.none)

type alias CalendarData =
    { schedIndex : Int
    }

type alias Model =
    { courses : CourseData
    , calendar : CalendarData
    , subjects : List Subject
    , coursesErr : String
    }

type Msg
    = GetSubjects
    | GetScheds
    | NewSubjects (Result Http.Error (List Subject))
    | NewScheds (Result Http.Error (CourseData))
    | IncrementSched
    | RenderCurrentSched

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        GetSubjects ->
            (model, getSubs)

        GetScheds ->
            (model, getScheds)

        NewSubjects (Ok newSubjects) ->
            ({ model | subjects = newSubjects}, Cmd.none)

        NewSubjects (Err e) ->
            ({model | subjects = [toString e]}, Cmd.none)

        NewScheds (Ok newScheds) ->
            {model | courses = newScheds, calendar = CalendarData 0}
                |> update RenderCurrentSched

        NewScheds (Err e) ->
            ({model | coursesErr = toString e}, Cmd.none)

        RenderCurrentSched ->
            (model, sched (makeSched model model.calendar.schedIndex))

        IncrementSched ->
            {model | calendar = CalendarData (model.calendar.schedIndex + 1)}
                |> update RenderCurrentSched

view model =
  div []
    [ button [ onClick GetSubjects ] [ text "Get Subs" ]
    , button [ onClick GetScheds ] [ text "Get Scheds" ]
    , button [ onClick IncrementSched ] [ text "Inc Sched" ]
    , List.map (\x -> x |> toString |> text) [
            model.calendar.schedIndex
        ] |> div []
    ]

getSubs : Cmd Msg
getSubs = Http.send NewSubjects (Http.get "/subjects" (list string))

getScheds : Cmd Msg
getScheds = Http.send NewScheds (Http.post "/courses" (Http.stringBody "application/json" body) decodeCourseData)

port sched : List (String, Section) -> Cmd a

makeSched : Model -> Int -> List (String, Section)
makeSched model comboIndex =
    let combo = case Array.get comboIndex model.courses.combos of
            Just c -> c
            Nothing -> Array.empty
        convertComboToClassList courseIndex classIndex =
            let maybeCourse = if classIndex > 0
                    then Array.get courseIndex model.courses.courses
                    else Nothing
                courseName  = case maybeCourse of
                    Just c -> c.title
                    Nothing -> ""
                maybeClass  = maybeCourse
                    |> andThen (\course -> Array.get (classIndex - 1) course.classes)
                    |> andThen (Array.get 0)
            in Maybe.map (\c -> (courseName, c)) maybeClass
    in Array.indexedMap convertComboToClassList combo
        |> Array.toList
        |> List.filterMap identity
