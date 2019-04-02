module Post exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Url.Builder as Builder



-- MODEL


type Model
    = Loading
    | Failed
    | Success Post


type alias Post =
    { id : Int
    , title : String
    , body : String
    , author : String
    , date : String
    }



-- REQUESTS


postDecoder : Decode.Decoder Post
postDecoder =
    Decode.succeed Post
        |> required "id" Decode.int
        |> required "title" Decode.string
        |> required "body" Decode.string
        |> required "author" Decode.string
        |> required "date" Decode.string


fetchPost : Int -> Cmd Msg
fetchPost id =
    Http.get
        { url = Builder.absolute [ "api", "posts", String.fromInt id ] []
        , expect = Http.expectJson Fetched postDecoder
        }



-- INIT


init : Int -> ( Model, Cmd Msg )
init id =
    ( Loading, fetchPost id )



-- UPDATE


type Msg
    = Fetched (Result Http.Error Post)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fetched result ->
            case result of
                Err _ ->
                    ( Failed, Cmd.none )

                Ok post ->
                    ( Success post, Cmd.none )



-- VIEW


view : Model -> ( String, Html Msg )
view model =
    case model of
        Loading ->
            ( "Loading post", text "Loading" )

        Failed ->
            ( "Failed to load post", text "Failed" )

        Success post ->
            ( post.title, div [] [ text (String.fromInt post.id), text post.title, text post.body, text post.author, text post.date ] )
