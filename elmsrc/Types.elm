module Types exposing (..)

import Array exposing (Array)
import Json.Decode exposing (field, int, string, array, map2, map3, map5)

type alias Sched = Array Int

type alias Subject = String
type alias Class = Array Section

type alias Section =
    { crn : Int
    , cap : Int
    , remaining: Int
    , instructor: String
    , daytimes: String
    }
type alias Course =
    { subject: Subject
    , courseNum: String
    , credits: String
    , title: String
    , classes: Array Class
    }
type alias CourseData =
    { schedCount : Int
    , courses : Array Course
    , combos : Array Sched
    }

decodeCourseData = map3 CourseData (field "sched_count" int) (field "flat_courses" (array decodeCourse)) (field "scheds" (array (array int)))
decodeCourse = map5 Course (field "subject" string) (field "course_num" string) (field "credits" string) (field "title" string) (field "classes" (array (array decodeSection)))
decodeSection = map5 Section (field "crn" int) (field "cap" int) (field "remaining" int) (field "instructor" string) (field "daytimes" string)

body = """{"courses":["SURVEY OF CHEMISTRY I","SURVEY OF CHEMISTRY II","CHEM I CONCEPT DEVELOPMENT","PRINCIPLES OF CHEMISTRY I","PRINCIPLES OF CHEMISTRY II","INTERMEDIATE ORG CHEM LAB I","ORGANIC CHEMISTRY I","ORGANIC CHEMISTRY PROBLEMS I","ORGANIC CHEMISTRY II"],"time_filter":{"start":"08:00:00 GMT-0400 (EDT)","end":"19:00:00 GMT-0400 (EDT)"},"credit_filter":{"min_hours":12,"max_hours":15},"instructor_filter":{}}"""
