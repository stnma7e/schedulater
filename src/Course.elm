module Course exposing (..)

import Dict exposing (Dict)
import Tuple exposing (pair)
import Array exposing (Array)
import Json.Decode as D exposing (field, index, int, string, array, map2, map3, map5)
import Maybe exposing (withDefault, andThen)

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
    , combos: Array Combo
    }

type alias CourseTableData =
    { courseNum: String
    , credits: String
    , title: String
    }

extractCourses : Subject -> CourseData -> Array Course
extractCourses sub cd = cd.courses
    |> Array.filter (\c -> c.subject == String.toUpper sub)

applyCombo : Array Course -> Combo -> Array (Maybe Class)
applyCombo courses combo = combo
    |> Array.indexedMap (\courseIdx classIdx ->
        Array.get courseIdx courses
            |> andThen (\course -> Array.get (classIdx - 1) course.classes))

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
