module Course exposing (..)

import Dict exposing (Dict)
import Tuple exposing (pair)
import Array exposing (Array)
import Json.Decode as D exposing (field, index, int, string, array, map2, map3, map5)
import Maybe exposing (withDefault, andThen)
import Tuple exposing (first)

import Common exposing (isJust)
import ClassTimes exposing (ClassTimes, getClassTimes)
import Combos exposing(Combo)

type alias CourseIndex = Int
type alias ClassIndex = Int

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
    { ident: CourseIdent
    , subject: SubjectIdent
    , credits: String
    , lectures: Array Class
    , labs: Array Class
    }

type alias CourseIdent = Ident
type alias SubjectIdent = Ident
type alias Ident =
    { internal: String
    , userFacing: String
    }
type alias IdentCmp = (String, String)
type alias CourseIdentCmp = (IdentCmp, IdentCmp)

type alias CourseDict = Dict CourseIdentCmp Course

emptyIdent = { internal = "", userFacing = "" }
fakeIdent = Debug.todo ""
ident2Cmp ident = (ident.internal, ident.userFacing)
cmp2Ident (internal, userFacing) = { internal = internal, userFacing = userFacing }

course2Cmp : Course -> CourseIdentCmp
course2Cmp course = (ident2Cmp course.ident, ident2Cmp course.subject)

cmp2Course : Array Course -> CourseIdentCmp -> Maybe (CourseIndex, Course)
cmp2Course courses ident = courses
    |> Array.indexedMap (\i x -> (i, x))
    |> Array.filter (\(courseIdx, course) -> course2Cmp course == ident)
    |> Array.get 0

getCourseIdx : Array Course -> CourseIdentCmp -> Maybe CourseIndex
getCourseIdx courses ident = Maybe.map first <| cmp2Course courses ident

type alias CourseData =
    { schedCount: Int
    , courses: Array Course
    , combos: Array Combo
    }

type alias CourseTableData =
    { courseNum: String
    , credits: String
    , title: String
    }

extractCourses : SubjectIdent -> CourseData -> Array Course
extractCourses sub cd = cd.courses
    |> Array.filter (\c -> String.toUpper c.subject.internal == String.toUpper sub.internal)

applyCombo : Array Course -> Combo -> Array (Maybe (Course, Class))
applyCombo courses combo = combo
    |> Array.indexedMap (\courseIdx classIdx ->
        Array.get courseIdx courses
            |> andThen (\course ->
                case Array.get (classIdx - 1) course.lectures of
                    Just class -> Just (course, class) -- if this class is a lecture
                    Nothing -> -- if this class is a lab, we need to subtract out the lecture indicies
                        Array.get (classIdx - 1 - Array.length course.lectures) course.labs
                            |> Maybe.map (\class -> (course, class))
                ))


findCourseIndex : Course -> CourseData -> Maybe CourseIndex
findCourseIndex course cd = cd.courses
    |> Array.indexedMap (\courseIdx other ->
        if course == other
            then Just courseIdx
            else Nothing
        )
    |> Array.filter isJust
    |> Array.foldl (\courseInfo acc -> courseInfo) Nothing

findSection : Int -> Array Course -> Maybe (CourseIdentCmp, ClassIndex)
findSection crn courses = courses
    |> Array.map (\course -> course.lectures
        |> Array.indexedMap (\sectionIdx sections -> case Array.get 0 sections of
            -- just choose the first section in that course's timeslot
                (Just section) -> if section.crn == crn
                    then Just sectionIdx
                    else Nothing
                Nothing -> Nothing )
        |> Array.filter isJust
        |> Array.foldl (\sectionIdx acc -> sectionIdx) Nothing
        |> Maybe.map (pair <| course2Cmp course))
    |> Array.filter isJust
    |> Array.foldl (\courseInfo acc -> courseInfo) Nothing

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
                    Just c -> c.ident.userFacing
                    Nothing -> ""
                maybeClass  = maybeCourse
                    |> andThen (\course -> Array.get (classIndex - 1) course.lectures)
                    |> andThen (Array.get 0)
            in Maybe.map (\c -> (courseName, c)) maybeClass
    in applyCombo courses.courses combo
        |> Array.toList
        |> List.filterMap (Maybe.andThen (\(course, class) -> Array.get 0 class
            |> Maybe.map (\section -> (course.ident.userFacing, section))))
