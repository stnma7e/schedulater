module Course exposing (..)

import Dict exposing (Dict)
import Tuple exposing (pair)
import Array exposing (Array)
import Json.Decode as D exposing (field, index, int, string, array, map2, map3, map5)
import Maybe exposing (withDefault, andThen)

import ClassTimes exposing (ClassTimes, getClassTimes)

type alias CourseIndex = Int
type alias ClassIndex = Int
type alias Sched = Array Int

type alias Subject = String

type alias Section =
    { crn: Int
    , cap: Int
    , remaining: Int
    , instructor: String
    , daytimes: ClassTimes
    }

-- a list of sections of a course that occur at the same time
type alias Class = Array Section

type alias Course =
    { subject: Subject
    , courseNum: String
    , credits: String
    , title: String
    , classes: Array Class
    }

type alias CourseIdent = Ident
type alias SubjectIdent = Ident
type alias Ident =
    { internal: String
    , userFacing: String
    }
type alias IdentCmp = (String, String)

type alias CourseDict = Dict (IdentCmp, IdentCmp) Course

emptyIdent = { internal = "", userFacing = "" }
fakeIdent = Debug.todo ""
ident2Cmp ident = (ident.internal, ident.userFacing)
cmp2Ident (internal, userFacing) = { internal = internal, userFacing = userFacing }

type alias CourseData =
    { schedCount: Int
    , courses: Array Course
    , combos: Array Sched
    }

type alias CourseTableData =
    { courseNum: String
    , credits: String
    , title: String
    }

extractCourses : Subject -> CourseData -> Array Course
extractCourses sub cd = cd.courses
    |> Array.filter (\c -> c.subject == String.toUpper sub)

findCourseIndex : Course -> CourseData -> Maybe CourseIndex
findCourseIndex course cd = cd.courses
    |> Array.indexedMap (\courseIdx other ->
        if course == other
            then Just courseIdx
            else Nothing
        )
    |> Array.filter isJust
    |> Array.foldl (\courseInfo acc -> courseInfo) Nothing


findSection : Int -> CourseData -> Maybe (CourseIndex, ClassIndex)
findSection crn cd = cd.courses
    |> Array.indexedMap (\courseIdx course -> course.classes
        |> Array.indexedMap (\sectionIdx sections -> case Array.get 0 sections of
            -- just choose the first section in that course's timeslot
                (Just section) -> if section.crn == crn
                    then Just sectionIdx
                    else Nothing
                Nothing -> Nothing )
        |> Array.filter isJust
        |> Array.foldl (\sectionIdx acc -> sectionIdx) Nothing
        |> Maybe.map (pair courseIdx)
    )
    |> Array.filter isJust
    |> Array.foldl (\courseInfo acc -> courseInfo) Nothing

decodeCourseData = map3 CourseData
    (field "sched_count" int)
    (field "flat_courses" (array decodeCourse))
    (field "scheds" (array (array int)))
decodeCourse = map5 Course
    (field "subject" string)
    (field "course_num" string)
    (field "credits" string)
    (field "title" string)
    (field "classes" (array (array decodeSection)))
decodeSection = map5 Section
    (field "crn" int)
    (field "cap" int)
    (field "remaining" int)
    (field "instructor" string)
    (field "daytimes" string
        |> D.andThen parseClassTimes)
decodeCourseTableData = map3 CourseTableData
    (index 0 string)
    (index 1 string)
    (index 2 string)

parseClassTimes : String -> D.Decoder ClassTimes
parseClassTimes daytimes =
    case getClassTimes daytimes of
        Just ct -> D.succeed ct
        Nothing -> D.fail ""

makeSched : CourseData -> Int -> List (String, Section)
makeSched courses comboIndex =
    let combo = case Array.get comboIndex courses.combos of
            Just c -> c
            Nothing -> Array.empty
        convertComboToClassList courseIndex classIndex =
            let maybeCourse = if classIndex > 0
                    then Array.get courseIndex courses.courses
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

isJust x = case x of
    Just _  -> True
    Nothing -> False
