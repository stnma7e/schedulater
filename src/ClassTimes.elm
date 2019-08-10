module ClassTimes exposing (..)

import Dict exposing (Dict)
import Bitwise exposing (shiftLeftBy)
import Maybe exposing (withDefault, andThen)
import Result exposing (withDefault)
import Parser exposing (Parser, (|=), (|.), run, succeed, int, symbol,
    oneOf, chompIf, chompWhile, getChompedString)
import Tuple exposing (pair)
import Debug exposing (log)

type alias ClassTimes = List ClassTime
type alias ClassTime =
    { startEndTime: StartEndTime
    , days: Days
    }
type alias StartEndTime =
    { start: Int
    , end: Int
    }
type alias Days = Int

sequence2 : List a -> List a -> List (a, a)
sequence2 a b = List.map (\a1 -> List.map (\b1 -> (a1, b1)) b) a
    |> List.foldl (++) []

checkClassTimesCollide : ClassTimes -> ClassTimes -> Bool
checkClassTimesCollide ct1 ct2 = sequence2 ct1 ct2
    |> List.map (\(ct11, ct22) -> checkClassTimeConflict ct11 ct22)
    |> List.foldl (||) False

-- returns true if conflict
checkClassTimeConflict : ClassTime -> ClassTime -> Bool
checkClassTimeConflict ct1 ct2 = if ((Bitwise.and ct1.days ct2.days) == 0)
    then False
    else [0,1,2,3,4,5,6]
        |> List.foldl (\day acc -> acc
            && if Bitwise.and
                    (Bitwise.and ct1.days (shiftLeftBy day 1))
                    (Bitwise.and ct2.days (shiftLeftBy day 1))
                    == 0
                then True
                else timesValid ct1 ct2)
            True

timesValid ct1 ct2 = not <|
       (ct1.startEndTime.end <= ct2.startEndTime.start)
    || (ct1.startEndTime.start >= ct2.startEndTime.end)

timeRangeValid : StartEndTime -> ClassTimes -> Bool
timeRangeValid set ct = ct
    |> List.map (\ct1 -> ct1.startEndTime.start >= set.start
        && ct1.startEndTime.end <= set.end)
    |> List.foldl (&&) True

getClassTimes : String -> Maybe ClassTimes
getClassTimes s = case run classTimes s of
    Ok ct -> Just ct
    Err err -> let l = log ("error parsing daytimes, " ++ s) err
                in Nothing

classTimes : Parser ClassTimes
classTimes = Parser.sequence
    { start = ""
    , separator = ";"
    , end = ""
    , spaces = Parser.spaces
    , item = classTime
    , trailing = Parser.Optional
    }

classTime : Parser ClassTime
classTime = succeed ClassTime
    |= startEndTime
    |. symbol "|"
    |= days

days : Parser Days
days = succeed identity
    |= chompWhile isDayLetter
    |> getChompedString
    |> Parser.map (\daysString -> Maybe.withDefault 0
        <| convertDayStringToInt daysString)

startEndTime : Parser StartEndTime
startEndTime = succeed StartEndTime
    |= time |. (symbol ",") |= time

time : Parser Int
time = succeed pair
    |= num |. (symbol ":") |= num
    |> Parser.map (\(t1, t2) -> t1*60 + t2)

num : Parser Int
num = succeed identity
    |. chompWhile Char.isDigit
    |> getChompedString
    |> Parser.map (\n -> Maybe.withDefault 0 <| String.toInt n)

isDayLetter : Char -> Bool
isDayLetter c = not <| List.isEmpty <| List.filter ((==) c) (String.toList "MTWRFSU")

convertDayStringToInt : String -> Maybe Days
convertDayStringToInt s =
    List.foldl (\day mask -> Dict.get day daysMap
        |> andThen (\day1 -> Maybe.map (\mask1 -> Bitwise.or day1 mask1) mask))
    (Just 0) <| String.toList s

daysMap = Dict.fromList <|
    [ ('M', shiftLeftBy 0 1)
    , ('T', shiftLeftBy 1 1)
    , ('W', shiftLeftBy 2 1)
    , ('R', shiftLeftBy 3 1)
    , ('F', shiftLeftBy 4 1)
    , ('S', shiftLeftBy 5 1)
    , ('U', shiftLeftBy 6 1)
    ]
