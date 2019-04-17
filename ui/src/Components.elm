module Components exposing (button)

import Html
import Html.Attributes exposing (class)


button : List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
button attrs body =
    let
        buttonAttrs =
            [ class "bg-white"
            , class "text-grey-light"
            , class "hover:bg-green"
            , class "hover:text-white"
            , class "border"
            , class "border-grey-light"
            , class "rounded"
            , class "shadow"
            , class "font-semibold"
            , class "py-1"
            , class "px-3"
            ]
    in
    Html.button (List.append buttonAttrs attrs) body
