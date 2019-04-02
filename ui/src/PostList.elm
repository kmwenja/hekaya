module PostList exposing (Model, Msg, init, update, view)

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
            ( "Loading Posts", div [] [ text "Loading", viewFilters filters ] )

        Failed filters ->
            ( "Failed to load posts", div [] [ text "Failed", viewFilters filters ] )

        Success filters postList ->
            ( "Posts"
            , div []
                [ viewFilters filters
                , ul [] (List.map viewEntry postList)
                ]
            )


viewFilters : Filters -> Html Msg
viewFilters filters =
    div []
        [ text "Next"
        , text filters.next
        , text "Previous"
        , text filters.prev
        , text "Page Size"
        , text (String.fromInt filters.pageSize)
        ]


viewEntry : PostEntry -> Html Msg
viewEntry entry =
    li [] [ text (String.fromInt entry.id), text entry.title, text entry.description, text entry.author, text entry.date ]
