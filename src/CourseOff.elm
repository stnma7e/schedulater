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
    | NewSubjectCourses SubjectIdent (Result Http.Error (List CourseOffSubjectCourse))
    | GetCourseInfo String String
    | NewCourseInfo String String (Result Http.Error (List CourseOffCourseInfo))

type alias CourseOffData =
    { subjects: List SubjectIdent
    , subjectCourses: Dict String (List CourseTableData)
    , courses: Dict String Course
    }

defaultCourseOffData =
    { subjects = []
    , subjectCourses = Dict.empty
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

    -- GetSubjectCourses sub -> (data, getSubjectCourses sub)
    -- NewSubjectCourses sub (Ok subCourses) ->
    --     let newSubCourse = Dict.insert sub
    --             (List.map subjectCourseToCourseTableData subCourses)
    --             data.subjectCourses
    --     in ({ data | subjectCourses = newSubCourse }, Cmd.none)
    -- NewSubjectCourses sub (Err err) ->
    --     Debug.todo ""
    --
    -- GetCourseInfo sub courseNum -> (data, getCourseInfo sub courseNum)
    -- NewCourseInfo sub courseNum (Ok courseInfo) ->
    --     let newCourseInfo = Dict.insert (sub ++ courseNum)
    --             (courseOffToMine sub courseNum courseInfo)
    --             data.courses
    --     in ({ data | courses = newCourseInfo }, Cmd.none)
    -- NewCourseInfo sub courseNum (Err err) ->
    --     Debug.todo ""

    otherwise -> (data, Cmd.none)

getCourseOffSubjects : Cmd CourseOffMsg
getCourseOffSubjects = Http.get
    { url = courseOffUrl ++ "majors"
    , expect = Http.expectJson NewSubjects (list decodeCourseOffSubject)
    }

-- getSubjectCourses : String -> Cmd CourseOffMsg
-- getSubjectCourses sub = Http.get
--     { url = courseOffUrl ++ "majors/" ++ sub ++ "/courses"
--     , expect = Http.expectJson (NewSubjectCourses sub)
--         <| list decodeCourseOffSubjectCourse
--     }
-- --
-- -- getCourseInfo : String -> String -> Cmd CourseOffMsg
-- -- getCourseInfo sub courseNum = Http.get
-- --     { url = courseOffUrl ++ "majors/" ++ sub ++ "/courses/" ++ courseNum ++ "/sections"
-- --     , expect = Http.expectJson (NewCourseInfo sub courseNum)
-- --         <| list decodeCourseOffCourseInfo
-- --     }
-- --
-- -- subjectCourseToCourseTableData : CourseOffSubjectCourse -> CourseTableData
-- -- subjectCourseToCourseTableData csc =
-- --     { courseNum = csc.ident
-- --     , title = csc.name
-- --     , credits = "0.000"
-- --     }

-- courseOffToMine : String -> String -> List CourseOffCourseInfo -> Course
-- courseOffToMine sub courseNum info =
--     let classes = Array.fromList <| List.map (\coc -> coc.timeslots
--                     |> Array.fromList
--                     |> Array.map courseOffTimeslotToSection) info
--         credits = List.head info
--                 |> Maybe.map (\c -> c.credits)
--                 |> Maybe.withDefault "0"
--     in { subject = sub
--        , courseNum = courseNum
--        , credits = credits
--        , title = courseNum
--        , classes = classes
--        }

courseOffTimeslotToSection : Timeslot -> Section
courseOffTimeslotToSection ts = Debug.todo ""

type alias CourseOffSubjectCourse =
    { ident: String
    , name: String
    }

type alias CourseOffCourseInfo =
    { callNumber: Int
    , credits: String
    , ident: String
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

decodeCourseOffSubject = map2 Ident
    (field "ident" string)
    (field "name" string)

decodeCourseOffSubjectCourse = map2 CourseOffSubjectCourse
    (field "ident" string)
    (field "name" string)

decodeCourseOffCourseInfo = map5 CourseOffCourseInfo
    (field "call_number" int)
    (field "credits" string)
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
