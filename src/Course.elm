module Course exposing (..)

import Dict
import Array exposing (Array)
import Json.Decode exposing (field, index, int, string, array, map2, map3, map5)
import Maybe exposing (withDefault, andThen)

type alias CourseIndex = Int
type alias ClassIndex = Int
type alias Sched = Array Int

type alias Subject = String

type alias Section =
    { crn: Int
    , cap: Int
    , remaining: Int
    , instructor: String
    , daytimes: String
    }

type alias Class = Array Section

type alias Course =
    { subject: Subject
    , courseNum: String
    , credits: String
    , title: String
    , classes: Array Class
    }

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

findCourse : String -> CourseData -> Maybe CourseIndex
findCourse title cd = cd.courses
    |> Array.indexedMap (\courseIdx course ->
        if course.title == title
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
        |> Maybe.map ((,) courseIdx)
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
    (field "daytimes" string)
decodeCourseTableData = map3 CourseTableData
    (index 0 string)
    (index 1 string)
    (index 2 string)

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
