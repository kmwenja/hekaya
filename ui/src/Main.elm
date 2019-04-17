module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy exposing (lazy)
import Http
import Post
import PostList
import Url
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


type Page
    = PostListPage PostList.Model
    | PostPage Post.Model
    | BlankPage


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , page : Page
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
    case getRoute url of
        HomeRoute ->
            let
                ( m, c ) =
                    PostList.init
            in
            ( Model url key (PostListPage m), Cmd.map PostListMsg c )

        PostRoute id ->
            let
                ( m, c ) =
                    Post.init id
            in
            ( Model url key (PostPage m), Cmd.map PostMsg c )

        NotFound ->
            ( Model url key BlankPage, Cmd.none )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | PostListMsg PostList.Msg
    | PostMsg Post.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                newModel =
                    { model | url = url }
            in
            case getRoute url of
                HomeRoute ->
                    let
                        ( m, c ) =
                            PostList.init
                    in
                    ( { newModel | page = PostListPage m }, Cmd.map PostListMsg c )

                PostRoute id ->
                    let
                        ( m, c ) =
                            Post.init id
                    in
                    ( { newModel | page = PostPage m }, Cmd.map PostMsg c )

                NotFound ->
                    ( { newModel | page = BlankPage }, Cmd.none )

        PostListMsg actualMsg ->
            case model.page of
                PostListPage postListModel ->
                    let
                        ( m, c ) =
                            PostList.update actualMsg postListModel
                    in
                    ( { model | page = PostListPage m }, Cmd.map PostListMsg c )

                _ ->
                    ( model, Cmd.none )

        PostMsg actualMsg ->
            case model.page of
                PostPage postModel ->
                    let
                        ( m, c ) =
                            Post.update actualMsg postModel
                    in
                    ( { model | page = PostPage m }, Cmd.map PostMsg c )

                _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        BlankPage ->
            pageView "Not Found" (text "Not Found")

        PostListPage postListModel ->
            let
                ( title, body ) =
                    PostList.view postListModel
            in
            pageView title (Html.map PostListMsg body)

        PostPage postModel ->
            let
                ( title, body ) =
                    Post.view postModel
            in
            pageView title (Html.map PostMsg body)


formatTitle : String -> String
formatTitle title =
    if String.length title > 0 then
        title ++ " - Hekaya"

    else
        "Hekaya"


pageView : String -> Html Msg -> Browser.Document Msg
pageView title body =
    { title = formatTitle title
    , body =
        [ viewHeader
        , div [ class "container", class "mx-auto" ]
            [ body
            ]
        ]
    }


viewHeader : Html Msg
viewHeader =
    div
        [ class "flex", class "items-center" ]
        [ div [ class "container", class "mx-auto", class "flex", class "flex-row", class "py-5" ]
            [ a [ class "block", class "mr-5", href "/" ] [ text "Hekaya" ]
            , ul [ class "inline-flex", class "flex-row", class "list-reset" ]
                [ li [] [ a [ class "flex-1", class "block", class "mr-5", href "/" ] [ text "Posts" ] ]
                , li [] [ a [ class "flex-1", class "block", class "mr-5", href "/write" ] [ text "Write" ] ]
                ]
            ]
        ]
