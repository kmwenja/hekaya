module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Url
import Url.Builder as Builder
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, top)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type Model
    = SplashPage Session
    | Blank Session
    | PostListLoadingPage Session Filters
    | PostListFailedPage Session Filters
    | PostListPage Session Filters PostList
    | PostLoadingPage Session
    | PostFailedPage Session
    | PostPage Session Post


type alias Session =
    { key : Nav.Key
    , url : Url.Url
    }


type alias Filters =
    { next : String
    , prev : String
    , pageSize : Int
    }


type alias PostList =
    List PostEntry


type alias PostEntry =
    { id : Int
    , title : String
    , description : String
    , author : String
    , date : String
    }


type alias Post =
    { id : Int
    , title : String
    , body : String
    , author : String
    , date : String
    }



-- ROUTING


type Route
    = HomeRoute
    | PostRoute Int
    | NotFound


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map HomeRoute top
        , map PostRoute (s "post" </> int)
        ]


getRoute : Url.Url -> Route
getRoute url =
    Maybe.withDefault NotFound (parse routeParser url)



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        session =
            Session key url
    in
    case getRoute url of
        HomeRoute ->
            ( SplashPage session, fetchPostList defaultFilters )

        PostRoute id ->
            ( SplashPage session, fetchPost id )

        NotFound ->
            ( Blank session, Cmd.none )



-- REQUESTS


defaultFilters : Filters
defaultFilters =
    Filters "" "" 25


fetchPostList : Filters -> Cmd Msg
fetchPostList filters =
    Http.get
        { url = Builder.absolute [ "api", "posts" ] [ Builder.string "next" filters.next, Builder.string "prev" filters.prev, Builder.int "page_size" filters.pageSize ]
        , expect = Http.expectJson FetchedPostList postListDecoder
        }


postListDecoder : Decode.Decoder PostList
postListDecoder =
    Decode.list
        (Decode.succeed PostEntry
            |> required "id" Decode.int
            |> required "title" Decode.string
            |> required "description" Decode.string
            |> required "author" Decode.string
            |> required "date" Decode.string
        )


fetchPost : Int -> Cmd Msg
fetchPost id =
    Http.get
        { url = Builder.absolute [ "api", "posts", String.fromInt id ] []
        , expect = Http.expectJson FetchedPost postDecoder
        }


postDecoder : Decode.Decoder Post
postDecoder =
    Decode.succeed Post
        |> required "id" Decode.int
        |> required "title" Decode.string
        |> required "body" Decode.string
        |> required "author" Decode.string
        |> required "date" Decode.string



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | FetchedPostList (Result Http.Error PostList)
    | FetchedPost (Result Http.Error Post)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    let
                        session =
                            getSession model
                    in
                    ( model, Nav.pushUrl session.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                oldSession =
                    getSession model

                newSession =
                    { oldSession | url = url }
            in
            case getRoute url of
                HomeRoute ->
                    ( PostListLoadingPage newSession defaultFilters, fetchPostList defaultFilters )

                PostRoute id ->
                    ( PostLoadingPage newSession, fetchPost id )

                NotFound ->
                    ( Blank newSession, Cmd.none )

        FetchedPostList result ->
            case result of
                Ok postList ->
                    case model of
                        SplashPage session ->
                            ( PostListPage session defaultFilters postList, Cmd.none )

                        PostListLoadingPage session filters ->
                            ( PostListPage session filters postList, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    case model of
                        SplashPage session ->
                            ( PostListFailedPage session defaultFilters, Cmd.none )

                        PostListLoadingPage session filters ->
                            ( PostListFailedPage session filters, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

        FetchedPost result ->
            case result of
                Ok post ->
                    case model of
                        SplashPage session ->
                            ( PostPage session post, Cmd.none )

                        PostLoadingPage session ->
                            ( PostPage session post, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    case model of
                        SplashPage session ->
                            ( PostFailedPage session, Cmd.none )

                        PostLoadingPage session ->
                            ( PostFailedPage session, Cmd.none )

                        _ ->
                            ( model, Cmd.none )


getSession : Model -> Session
getSession model =
    case model of
        SplashPage session ->
            session

        Blank session ->
            session

        PostListLoadingPage session _ ->
            session

        PostListFailedPage session _ ->
            session

        PostListPage session _ _ ->
            session

        PostLoadingPage session ->
            session

        PostFailedPage session ->
            session

        PostPage session _ ->
            session



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model of
        SplashPage session ->
            { title = "Hekaya"
            , body = [ viewLinks, text "Splash", viewSession session ]
            }

        Blank session ->
            { title = "Not Found - Hekaya"
            , body = [ viewLinks, text "Not Found", viewSession session ]
            }

        PostListLoadingPage session filters ->
            { title = "Post List Loading - Hekaya"
            , body = [ viewLinks, text "Post List Loading", viewSession session, viewFilters filters ]
            }

        PostListFailedPage session filters ->
            { title = "Post List Failed - Hekaya"
            , body = [ viewLinks, text "Post List Failed", viewSession session, viewFilters filters ]
            }

        PostListPage session filters postList ->
            { title = "Post List - Hekaya"
            , body = [ viewLinks, text "Post List", viewSession session, viewFilters filters, viewPostList postList ]
            }

        PostLoadingPage session ->
            { title = "Post Loading - Hekaya"
            , body = [ viewLinks, text "Post Loading", viewSession session ]
            }

        PostFailedPage session ->
            { title = "Post Failed - Hekaya"
            , body = [ viewLinks, text "Post Failed", viewSession session ]
            }

        PostPage session post ->
            { title = "Post - Hekaya"
            , body = [ viewLinks, text "Post", viewSession session, viewPost post ]
            }


viewSession : Session -> Html Msg
viewSession session =
    div [] [ text "Url", text (Url.toString session.url) ]


viewFilters : Filters -> Html Msg
viewFilters filters =
    div [] [ text "Next", text filters.next, text "Previous", text filters.prev, text "Page Size", text (String.fromInt filters.pageSize) ]


viewPostList : PostList -> Html Msg
viewPostList postList =
    ul [] (List.map viewPostEntry postList)


viewPostEntry : PostEntry -> Html Msg
viewPostEntry post =
    li [] [ text (String.fromInt post.id), text post.title, text post.description, text post.author, text post.date ]


viewPost : Post -> Html Msg
viewPost post =
    div [] [ text (String.fromInt post.id), text post.title, text post.body, text post.author, text post.date ]


viewLinks : Html Msg
viewLinks =
    ul []
        [ li [] [ a [ href "/" ] [ text "/" ] ]
        , li [] [ a [ href "/post/1" ] [ text "/post/1" ] ]
        , li [] [ a [ href "/post/2" ] [ text "/post/2" ] ]
        , li [] [ a [ href "/unknown" ] [ text "/unknown" ] ]
        ]
