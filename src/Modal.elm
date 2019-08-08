module Modal exposing (..)

import Html exposing (Html, div, text, button)
import Html.Attributes as HA exposing (class)
import Html.Events exposing (onClick)

import Msg exposing (Msg(..))

modal : Bool -> Msg -> List (Html Msg) -> Html Msg
modal isActive closeMsg content =
    div [ class <| "modal" ++ if isActive then " " ++ "is-active" else "" ]
        [ div
            [ class "modal-background"
            , onClick closeMsg
            ]
            []
        , div [ class "modal-content" ]
            content
        , button [ class "modal-close is-large", onClick closeMsg ]
            []
        ]
