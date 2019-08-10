module Common exposing (..)

sequence : List (Maybe a) -> Maybe (List a)
sequence mss = case mss of
    [] -> Just []
    (m::ms) -> m |> Maybe.andThen
        (\x -> sequence ms |> Maybe.andThen
            (\xs -> Just (x::xs)))

flip f a b = f b a

isJust x = case x of
    Nothing -> False
    Just _ -> True
