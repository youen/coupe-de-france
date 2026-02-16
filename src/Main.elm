module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode as Decode
import Model exposing (..)


type alias Model =
    { planning : List Creneau
    , contexte : UserContext
    }


type Msg
    = SelectEquipe String
    | ResetContexte


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        decodedPlanning =
            Decode.decodeValue rootDecoder flags
                |> Result.withDefault []
    in
    ( { planning = decodedPlanning, contexte = PourPatineur "" }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectEquipe name ->
            ( { model | contexte = PourPatineur name }, Cmd.none )

        ResetContexte ->
            ( { model | contexte = PourPatineur "" }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "max-w-4xl mx-auto p-4" ]
        [ h1 [ class "text-3xl font-bold text-[#ea3a60] mb-6 cursor-pointer", onClick ResetContexte ] [ text "Planning Coupe de France" ]
        , viewSelection model
        , div [ class "space-y-2" ]
            (viewPlanning model)
        ]


viewSelection : Model -> Html Msg
viewSelection model =
    let
        equipes =
            getEquipes model.planning
    in
    div [ class "mb-6" ]
        [ label [ class "block text-sm font-medium text-gray-700 mb-2" ] [ text "Sélectionner une équipe :" ]
        , select
            [ class "block w-full p-2 border border-gray-300 rounded-md focus:ring-[#ea3a60] focus:border-[#ea3a60]"
            , onChange SelectEquipe
            ]
            (option [ value "" ] [ text "-- Toutes les équipes --" ]
                :: List.map (\eq -> option [ value eq, selected (isTeamSelected eq model.contexte) ] [ text eq ]) equipes
            )
        ]


isTeamSelected : String -> UserContext -> Bool
isTeamSelected name contexte =
    case contexte of
        PourPatineur n ->
            n == name

        _ ->
            False


viewPlanning : Model -> List (Html Msg)
viewPlanning model =
    case model.contexte of
        PourPatineur "" ->
            List.map viewCreneau (prepareViewData model.planning)

        PourPatineur teamName ->
            List.map viewCreneau (getHorairesPatineur teamName model.planning)

        _ ->
            []


viewCreneau : ViewCreneau -> Html Msg
viewCreneau creneau =
    div [ class "flex items-center gap-4 p-3 bg-white border-b border-gray-100" ]
        [ div [ class "w-16 font-semibold text-gray-600" ] [ text creneau.time ]
        , div [ class "flex-1" ]
            [ div [ class "font-bold text-gray-800" ] [ text creneau.name ]
            , if String.isEmpty creneau.category then
                text ""

              else
                div [ class "text-sm text-gray-500" ] [ text creneau.category ]
            ]
        ]



-- Helper for select change


onChange : (String -> msg) -> Attribute msg
onChange tagger =
    Html.Events.on "change" (Decode.map tagger Html.Events.targetValue)


onClick : msg -> Attribute msg
onClick msg =
    Html.Events.on "click" (Decode.succeed msg)


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
