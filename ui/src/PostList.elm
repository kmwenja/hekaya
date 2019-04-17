module PostList exposing (Model, Msg, init, update, view)

import Components
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Url.Builder as Builder



-- MODEL


type Model
    = Loading Filters
    | Failed Filters
    | Success Filters (List PostEntry)


type alias Filters =
    { next : String
    , prev : String
    , pageSize : Int
    }


defaultFilters : Filters
defaultFilters =
    Filters "" "" 25


type alias PostEntry =
    { id : Int
    , title : String
    , description : String
    , author : String
    , date : String
    }



-- REQUESTS


postListDecoder : Decode.Decoder (List PostEntry)
postListDecoder =
    Decode.list
        (Decode.succeed PostEntry
            |> required "id" Decode.int
            |> required "title" Decode.string
            |> required "description" Decode.string
            |> required "author" Decode.string
            |> required "date" Decode.string
        )


fetchPostList : Filters -> Cmd Msg
fetchPostList filters =
    Http.get
        { url = Builder.absolute [ "api", "posts" ] [ Builder.string "next" filters.next, Builder.string "prev" filters.prev, Builder.int "page_size" filters.pageSize ]
        , expect = Http.expectJson Fetched postListDecoder
        }



-- INIT


init : ( Model, Cmd Msg )
init =
    ( Loading defaultFilters, fetchPostList defaultFilters )



-- UPDATE


type Msg
    = Fetched (Result Http.Error (List PostEntry))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fetched result ->
            case result of
                Err _ ->
                    ( Failed (getFilters model), Cmd.none )

                Ok postList ->
                    ( Success (getFilters model) postList, Cmd.none )


getFilters : Model -> Filters
getFilters model =
    case model of
        Loading filters ->
            filters

        Failed filters ->
            filters

        Success filters _ ->
            filters



-- VIEW


view : Model -> ( String, Html Msg )
view model =
    case model of
        Loading filters ->
            ( "Loading Posts", pageView filters (div [ class "alert", class "alert-warning" ] [ text "Loading" ]) )

        Failed filters ->
            ( "Failed to load posts", pageView filters (div [ class "alert", class "alert-danger" ] [ text "Failed" ]) )

        Success filters postList ->
            ( "Posts"
            , pageView filters
                (div []
                    [ ul [ class "list-reset" ] (List.map viewEntry postList)
                    ]
                )
            )


pageView : Filters -> Html Msg -> Html Msg
pageView filters body =
    div []
        [ div [ class "mb-4" ]
            [ h3 [ class "mb-4" ] [ text "Posts" ]
            , div [ class "flex" ]
                [ input [ type_ "text", placeholder "Search", class "block", class "w-2/3", class "mr-4", class "bg-grey-lighter", class "appearance-none", class "border-2", class "border-grey-lighter", class "rounded", class "py-1", class "px-3", class "text-grey-darker", class "leading-tight", class "focus:outline-none", class "focus:bg-white", class "focus:border-green" ] []
                , select []
                    [ option [] [ text "Unread" ]
                    , option [] [ text "Read" ]
                    , option [] [ text "All" ]
                    ]
                ]
            ]
        , div [] [ body ]
        , div [ class "inline-flex" ]
            [ Components.button [ class "mr-2" ] [ text "Previous" ]
            , Components.button [] [ text "Next" ]
            ]
        ]


viewEntry : PostEntry -> Html Msg
viewEntry entry =
    li []
        [ div [ class "mb-4" ]
            [ div []
                [ a [ href (Builder.absolute [ "post", String.fromInt entry.id ] []) ] [ text entry.title ]
                , text " - "
                , text entry.description
                ]
            , div []
                [ text " by "
                , i [] [ text entry.author ]
                , text " on "
                , i [] [ text entry.date ]
                ]
            ]
        ]
