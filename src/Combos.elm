module Combos exposing (..)

import Debug exposing (log)
import Http
import List exposing (tail, head)
import Array exposing (Array)
import Dict exposing (Dict)
import Maybe exposing (withDefault, andThen)

type alias Combo = Array Int
type alias Combos =
    { current: Combo,
      max: Combo
    }

incrementCombo : Combos -> Maybe Combos
incrementCombo c = incrementCombo1 c 0 False

checkDone c i = if i >= Array.length c.current
    then True
    else case getAtPosition i c of
        Just (j_current, j_max) -> if j_current >= j_max
            then checkDone c (i + 1)
            else False
        Nothing -> Debug.crash "why u broke"

incrementCombo1 c i flip = if checkDone c 0
    then Nothing
    else case incrementAtPosition i c of
        Just c1 -> if flip
            then Just { c1 | current = zeroBefore (Array.toList c1.current) i }
            else Just c1
        Nothing -> incrementCombo1 c (i + 1) True

zeroBefore : List Int -> Int -> Combo
zeroBefore c i = Array.fromList <| (List.repeat (i - 0) 0) ++ (List.drop (i - 0) c)

incrementAtPosition : Int -> Combos -> Maybe Combos
incrementAtPosition i c = getAtPosition i c |> andThen
    (\(j_current, j_max) -> if j_current < j_max
        then Just { c | current = Array.set i (j_current + 1) c.current }
        else Nothing)

getAtPosition : Int -> Combos -> Maybe (Int, Int)
getAtPosition i c = Array.get i c.current |> andThen
    (\j_current ->  Array.get i c.max |> andThen
        (\j_max -> Just (j_current, j_max)))
