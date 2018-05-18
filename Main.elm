import Html exposing (Html, input, button, label, div, text)
import Html.Events exposing (onInput, onClick)
import Http
import Json.Decode exposing (..)

main =
  Html.program { init = init, view = view, update = update , subscriptions = subscriptions}

-- MODEL

type alias Item =
  { name : String
  , id : Int
  , examine : String
  }

itemDecoder = map3 Item (field "name" string) (field "item_id" int) (field "examine" string)

type alias Model = 
  { searchstr: String
  , item : Item
  }

init : (Model, Cmd Msg)
init = 
  (Model "Iron Pickaxe" (Item "Iron Pickaxe" 666 "Pointy"), Cmd.none)

-- UPDATE

type Msg 
  = UpdateName String
  | DoSearch
  | LookupData (Result Http.Error Item)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateName str ->
      ( { model | searchstr = str }, Cmd.none )
    
    DoSearch ->
      ( model, lookupItem model.searchstr )

    LookupData (Ok newItem) -> 
      ( { model | item = newItem }, Cmd.none )
    
    LookupData (Err _) ->
      ( { model | item = (Item "Fail" -1 "Gremlins") }, Cmd.none )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = 
  Sub.none

-- VIEW
view : Model -> Html Msg
view model =
  div []
    [ label [] [ text "Look up: " ]
    , input [ onInput UpdateName ] []
    , button [ onClick DoSearch] [ text model.searchstr ]
    , div [] [ text model.item.name ]
    , div [] [ text ( toString model.item.id ) ]
    , div [] [ text model.item.examine ]
    ]

-- HTTP

lookupItem : String -> Cmd Msg
lookupItem name =
  let
    url = 
      "http://kevbase.com/osrs-stocks/api/lookup/name/" ++ name
  in
    Http.send LookupData (Http.get url itemDecoder)
  
