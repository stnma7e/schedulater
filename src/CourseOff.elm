module CourseOff exposing (..)

import Http
import Json.Decode exposing (int, string, list, field, map2, map5, map4)
import Array
import Dict exposing (Dict)
import Debug exposing (log)

import Course exposing (..)

courseOffUrl = "https://soc.courseoff.com/gatech/terms/201901/"

type CourseOffMsg
    = GetSubjects
    | NewSubjects (Result Http.Error (List SubjectIdent))
    | GetSubjectCourses SubjectIdent
    | NewSubjectCourses SubjectIdent (Result Http.Error (List CourseIdent))
    | NewCourseInfo SubjectIdent CourseIdent (Result Http.Error (List CourseOffSection))

type alias CourseOffData =
    { subjects: List SubjectIdent
    , courses: CourseDict
    }

defaultCourseOffData =
    { subjects = []
    , courses = Dict.empty
    }

update : CourseOffMsg -> CourseOffData -> (CourseOffData, Cmd CourseOffMsg)
update msg data = case msg of
    GetSubjects -> (data, getCourseOffSubjects)
    NewSubjects (Ok newSubjects) ->
        ({ data |  subjects = newSubjects }, Cmd.none)
    NewSubjects (Err e) ->
        let _ = log "ERROR [CourseOff NewSubjects]" <| Debug.toString e
        in (data, Cmd.none)

    GetSubjectCourses sub -> (data, getSubjectCourses sub)
    NewSubjectCourses sub (Ok subCourses) ->
        let courseInfoCmds = List.map (getCourseInfo sub) subCourses
        in (data, Cmd.batch courseInfoCmds)
    NewSubjectCourses sub (Err err) ->
        Debug.todo ""

    NewCourseInfo sub course (Ok courseInfo) ->
        let newCourseInfo = Dict.insert (ident2Cmp sub, ident2Cmp course)
                (courseOffToMine sub course courseInfo)
                data.courses
        in ({ data | courses = newCourseInfo }, Cmd.none)
    NewCourseInfo sub courseNum (Err err) ->
        Debug.todo ""

getCourseOffSubjects : Cmd CourseOffMsg
getCourseOffSubjects = Http.get
    { url = courseOffUrl ++ "majors"
    , expect = Http.expectJson NewSubjects (list decodeCourseOffSubject)
    }

getSubjectCourses : SubjectIdent -> Cmd CourseOffMsg
getSubjectCourses sub = Http.get
    { url = courseOffUrl ++ "majors/" ++ sub.internal ++ "/courses"
    , expect = Http.expectJson (NewSubjectCourses sub)
        <| list decodeCourseOffSubjectCourse
    }

getCourseInfo : SubjectIdent -> CourseIdent -> Cmd CourseOffMsg
getCourseInfo sub course = Http.get
    { url = courseOffUrl ++ "majors/" ++ sub.internal ++ "/courses/"
            ++ course.internal ++ "/sections"
    , expect = Http.expectJson (NewCourseInfo sub course)
        <| list decodeCourseOffCourseInfo
    }

courseOffToMine : SubjectIdent -> CourseIdent -> List CourseOffSection -> Course
courseOffToMine sub course info =
    let classes = Array.fromList []
        -- Array.fromList <| List.map (\coc -> coc.timeslots
        --             |> Array.fromList
        --             |> Array.map courseOffTimeslotToSection) info
        credits = List.head info
                |> Maybe.map (\c -> String.fromInt c.credits)
                |> Maybe.withDefault "0"
    in { subject = sub.userFacing
       , courseNum = course.internal
       , credits = credits
       , title = course.userFacing
       , classes = classes
       }

courseOffTimeslotToSection : Timeslot -> Section
courseOffTimeslotToSection ts = Debug.todo ""

type alias CourseOffSubjectCourse =
    { ident: String
    , name: String
    }

type alias CourseOffSection =
    { callNumber: Int
    , credits: Int
    , section: String
    , timeslots: List Timeslot
    , instructor: Instructor
    }

type alias Instructor =
    { lname: String
    , fname: String
    }

type alias Timeslot =
    { location: String
    , startTime: Int
    , endTime: Int
    , day: String
    }

decodeCourseOffSubject = decodeCourseOffXIdent
decodeCourseOffSubjectCourse = decodeCourseOffXIdent
decodeCourseOffXIdent = map2 Ident
    (field "ident" string)
    (field "name" string)

decodeCourseOffCourseInfo = map5 CourseOffSection
    (field "call_number" int)
    (field "credits" int)
    (field "ident" string)
    (field "timeslots" (list decodeTimeslot))
    (field "instructor"
        <| map2 Instructor
            (field "lname" string)
            (field "fname" string))

decodeTimeslot = map4 Timeslot
    (field "location" string)
    (field "start_time" int)
    (field "end_time" int)
    (field "day" string)
