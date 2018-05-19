module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (src, alt, href, class, style)
import Html.Events exposing (keyCode)

import Http
import Json.Decode as JD exposing (..)

import Material
import Material.Scheme
import Material.Button as Button
import Material.Textfield as Textfield
import Material.Table as Table
import Material.List as Lists
import Material.Options as Options exposing (css)

import LineChart
import LineChart.Junk as Junk exposing (..)
import LineChart.Dots as Dots
import LineChart.Container as Container
import LineChart.Interpolation as Interpolation
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis as Axis
import LineChart.Legends as Legends
import LineChart.Line as Line
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Legends as Legends
import LineChart.Area as Area
import Color

import Regex exposing (regex, escape, HowMany(..))

-- MODEL

type alias ChartData =
    { x : Float
    , y : Float
    }

dataDecoder = map2 ChartData
    (field "x" float)
    (field "y" float)

dataListDecoder = JD.list dataDecoder

type alias Item =
    { name : String
    , id : Int
    , examine: String
    }

itemDecoder = map3 Item 
    (field "name" string)
    (field "item_id" int)
    (field "examine" string)

suggestionsDecoder = JD.list string
        
type alias Model =
    { searchStr : String
    , searchSuggestions : List String
    , item : Item
    , iconUrl : String
    , chartHover : Maybe ChartData
    , chartData : List ChartData
    , mdl :
        Material.Model
        -- Boilerplate: model store for any and all Mdl components used
    }


model : Model
model =
    { searchStr = ""
    , searchSuggestions = []
    , item = (Item "" 0 "")
    , iconUrl = ""
    , chartHover = Nothing
    , chartData = []
    , mdl =
        Material.model
        -- Boilerplate: Always use this initial Mdl model store
    }



-- ACTION, UPDATE


type Msg
    = UpdateName String
    | UpdateSuggestions (Result Http.Error (List String))
    | UpdatePrices (Result Http.Error (List ChartData))
    | DoSearch
    | LookupData (Result Http.Error Item)
    | Hover (Maybe ChartData)
    | Mdl (Material.Msg Msg)

-- Boilerplate: Msg clause for internal Mdl messages.


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateName str ->
            ( { model | searchStr = str }
            , lookupSuggestions str
            )

        UpdateSuggestions (Ok lis) ->
            ( { model | searchSuggestions = lis } 
            , Cmd.none
            )
        
        UpdateSuggestions (Err _) ->
            ( { model | searchSuggestions = [] }
            , Cmd.none
            )

        UpdatePrices (Ok lis) ->
            ( { model | chartData = lis }
            , Cmd.none
            )

        UpdatePrices (Err _) ->
            ( { model | chartData = [] }
            , Cmd.none
            )

        DoSearch ->
            ( model
            , Cmd.batch [ lookupItem model.searchStr, lookupPrices model.searchStr ]
            )

        LookupData (Ok newItem) ->
            ( { model | item = newItem, iconUrl = "http://kevbase.com/osrs-stocks/api/icons/" ++ toString newItem.id}
            , Cmd.none
            )

        LookupData (Err _) ->
            ( { model | item = (Item "Fail" -1 "Gremlins"), iconUrl = "http://kevbase.com/osrs-stocks/static/error.png" }
            , Cmd.none
            )

        Hover hover ->
            ( { model | chartHover = hover }
            , Cmd.none
            )

        -- Boilerplate: Mdl action handler.
        Mdl msg_ ->
            Material.update Mdl msg_ model

isEnter : number -> JD.Decoder Msg
isEnter code = 
    if code == 13 then
        JD.succeed DoSearch
    else
        JD.fail "some other key"

-- VIEW


type alias Mdl =
    Material.Model

wikiLink : Item -> String
wikiLink item =
    "http://oldschoolrunescape.wikia.com/wiki/" ++ (item.name |> replace " " "_")

itemTable : Item -> Html Msg
itemTable item =
    Table.table []
    [ Table.thead []
        [ Table.tr []
            [ Table.th [] [ text "Variable" ] 
            , Table.th [] [ text "Value" ]
            ]
        ]
    , Table.tbody []
        [ Table.tr []
            [ Table.td [] [ text "Item" ]
            , Table.td [] [ text item.name ]
            ]
        , Table.tr []
            [ Table.td [] [ text "ID" ]
            , Table.td [] [ text (toString item.id) ]
            ]
        , Table.tr []
            [ Table.td [] [ text "Examine" ]
            , Table.td [] [ text item.examine ]
            ]
        , Table.tr []
            [ Table.td [] [ text "Wiki Page" ]
            , Table.td [] [ a [ href (wikiLink item) ] [ text "Link" ] ] 
            ]
        ]
    ]
    
suggestionList : List String -> Html Msg
suggestionList list =
    Lists.ul []
        (list |> List.map (\str ->
            Lists.li [] [ Lists.content [] [ text str ] ]
            )
        )

priceChart : Model -> Html Msg
priceChart model = 
    LineChart.viewCustom
        { y = Axis.default 450 "Price" .y
        , x = Axis.default 700 "Date?  Dunno" .x
        , container = Container.styled "line-chart-1" [ ("font-family", "monospace") ]
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.hoverOne Hover
        , junk = 
            Junk.hoverOne model.chartHover
                [ ( "X", toString << .x )
                , ( "Y", toString << .y )
                ]
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.hoverOne model.chartHover
        }
        [ LineChart.line Color.blue Dots.circle model.item.name model.chartData ]


view : Model -> Html Msg
view model =
    div
        [ style [ ( "padding", "2rem" ) ] ]
        [ table []
            [ tr []
                [ td [ style [ ( "vertical-align", "top" ) ] ]
                    [ Textfield.render Mdl
                        [ 0 ]
                        model.mdl
                        [ Textfield.label "Item Search"
                        , Textfield.floatingLabel
                        , css "margin" "0 24px"
                        , Options.onInput UpdateName
                        , Options.on "keydown" (JD.andThen isEnter keyCode)
                        , Textfield.value model.searchStr
                        ]
                        []
                    , Button.render Mdl
                        [ 1 ]
                        model.mdl
                        [ Options.onClick DoSearch ]
                        [ text "Search" ]
                    , suggestionList model.searchSuggestions
                    ]
                , td [ style [ ( "vertical-align", "top" ) ] ]
                    [ div [] [ itemTable model.item ]
                    , img 
                        [ src model.iconUrl
                        , alt "(Item image not yet scraped)"
                        , style 
                            [ ("width", "90px")
                            , ("height", "90px") 
                            ] 
                        ]
                        []
                    , td [] [ div [ class "container" ] [ priceChart model ] ]
                    ]
                ]
            ]
        ]
        |> Material.Scheme.top


-- Load Google Mdl CSS. May want to do that not in code as is done
-- do here, but rather in a master .html file. See the documentation
-- for the `Material` module for details.

-- HTTP
lookupItem : String -> Cmd Msg
lookupItem name =
    let
        url =
            "http://kevbase.com/osrs-stocks/api/lookup/name/" ++ name
    in
        Http.send LookupData (Http.get url itemDecoder)
                                          
lookupSuggestions : String -> Cmd Msg
lookupSuggestions name =
    let
        url = 
            "http://kevbase.com/osrs-stocks/api/search/" ++ name
    in
        Http.send UpdateSuggestions (Http.get url suggestionsDecoder)

lookupPrices : String -> Cmd Msg
lookupPrices name =
    let
        url =
            "http://kevbase.com/osrs-stocks/api/history/" ++ name
    in
        Http.send UpdatePrices (Http.get url dataListDecoder)

main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , view = view
        , subscriptions = always Sub.none
        , update = update
        }


-- UTILS
replace : String -> String -> String -> String
replace search substitution string =
        string
                |> Regex.replace All (regex (escape search)) (\_ -> substitution)
