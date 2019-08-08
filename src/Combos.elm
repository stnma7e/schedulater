module Combos exposing (..)

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
incrementCombo c = incrementCombo_ c 0 False

incrementCombo_ : Combos -> Int -> Bool -> Maybe Combos
incrementCombo_ c i flip = checkDone c 0
    |> andThen (\done -> if done
        then Nothing
        else case incrementAtPosition i c of
            Just c1 -> if flip
                then Just { c1 | current = zeroBefore (Array.toList c1.current) i }
                else Just c1
            Nothing -> incrementCombo_ c (i + 1) True)

checkDone : Combos -> Int -> Maybe Bool
checkDone c i = if i >= Array.length c.current
    then Just True
    else case getAtPosition i c of
        Just (j_current, j_max) -> if j_current >= j_max
            then checkDone c (i + 1)
            else Just False
        Nothing -> Nothing

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


currentCombo : Combos -> Int
currentCombo c =
    let magnitudes = Array.indexedMap
                (\i x -> maxCombo <| Array.slice 0 i c.max)
                c.max
    in Array.foldl (\(c1, c2) acc -> acc + c1 * c2) 0
        <| zip c.current magnitudes

maxCombo : Combo -> Int
maxCombo c = Array.foldl (\c1 acc -> acc * (c1 + 1)) 1 c

zip : Array a -> Array a -> Array (a, a)
zip a b = List.map2 (\a1 b1 -> (a1, b1)) (Array.toList a) (Array.toList b)
    |> Array.fromList
