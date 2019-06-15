module ClassTimes exposing (..)

import Dict exposing (Dict)
import Bitwise exposing (shiftLeftBy)
import Maybe exposing (withDefault)
import Parser exposing (Parser, (|=), (|.), run, succeed, int, symbol,
    keep, ignore, Count, zeroOrMore, oneOrMore)
import Debug exposing (log)

type alias ClassTimes = List ClassTime
type alias ClassTime =
    { startEndTime: StartEndTime
    , days: Days
    }
type alias StartEndTime = (Int, Int)
type alias Days = Int

getClassTimes : String -> Maybe ClassTimes
getClassTimes s = case run classTimes s of
    Ok ct -> Just ct
    Err err -> log ("error parsing daytimes") Nothing

classTimes : Parser ClassTimes
classTimes = Parser.repeat oneOrMore classTime

classTime : Parser ClassTime
classTime = succeed ClassTime
    |= startEndTime
    |. symbol "|"
    |= days
    |. ignore zeroOrMore (\c -> c == ';')

days : Parser Days
days = succeed identity
    |= keep oneOrMore isDayLetter
    |> Parser.map (\daysString -> withDefault 0 <| convertDayStringToInt daysString)

startEndTime : Parser StartEndTime
startEndTime = succeed (,)
    |= time |. (symbol ",") |= time

time : Parser Int
time = succeed (,)
    |= int |. symbol ":" |= int
    |> Parser.map (\(t1, t2) -> t1*60 + t2)

isDayLetter : Char -> Bool
isDayLetter c = not <| List.isEmpty <| List.filter ((==) c) (String.toList "MTWRFSU")

convertDayStringToInt : String -> Maybe Days
convertDayStringToInt s =
    List.foldl (\day mask -> case Dict.get day daysMap of
            Just day1 -> Maybe.map (\mask1 -> Bitwise.or day1 mask1) mask
            Nothing -> Nothing)
        Nothing <| String.toList s

daysMap = Dict.fromList <|
    [ ('M', shiftLeftBy 0 1)
    , ('T', shiftLeftBy 1 1)
    , ('W', shiftLeftBy 2 1)
    , ('R', shiftLeftBy 3 1)
    , ('F', shiftLeftBy 4 1)
    , ('S', shiftLeftBy 5 1)
    , ('U', shiftLeftBy 6 1)
    ]
