module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Json.Decode as Decode
import Model exposing (..)
import Set


type alias Model =
    { planning : List Creneau
    , contexte : Maybe UserContext
    }


type Msg
    = SelectEquipe String
    | ToggleEquipeCoach String
    | SelectVestiaire String
    | SetContexte UserContext
    | ResetContexte


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        decodedPlanning =
            Decode.decodeValue rootDecoder flags
                |> Result.withDefault []
    in
    ( { planning = decodedPlanning, contexte = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectEquipe name ->
            ( { model | contexte = Just (PourPatineur name) }, Cmd.none )

        ToggleEquipeCoach name ->
            case model.contexte of
                Just (PourCoach set) ->
                    let
                        newSet =
                            if Set.member name set then
                                Set.remove name set

                            else
                                Set.insert name set
                    in
                    ( { model | contexte = Just (PourCoach newSet) }, Cmd.none )

                _ ->
                    ( { model | contexte = Just (PourCoach (Set.singleton name)) }, Cmd.none )

        SelectVestiaire vStr ->
            let
                vNum =
                    String.toInt vStr |> Maybe.withDefault 0
            in
            ( { model | contexte = Just (PourVestiaire vNum) }, Cmd.none )

        SetContexte ctx ->
            ( { model | contexte = Just ctx }, Cmd.none )

        ResetContexte ->
            ( { model | contexte = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.contexte of
        Nothing ->
            viewRoleSelection

        Just ctx ->
            case ctx of
                PourVestiaire n ->
                    if n > 0 then
                        viewVestiairePrint model.planning n

                    else
                        viewStandardLayout model ctx

                _ ->
                    viewStandardLayout model ctx


viewRoleSelection : Html Msg
viewRoleSelection =
    div [ class "min-h-screen bg-white flex flex-col items-center justify-center p-6 gap-6" ]
        [ h1 [ class "text-4xl font-bold text-[#ea3a60] mb-8 text-center" ] [ text "CDF Synchro 2026" ]
        , div [ class "grid grid-cols-1 md:grid-cols-2 gap-4 w-full max-w-2xl" ]
            [ roleButton "Patineur" (PourPatineur "") "⛸️"
            , roleButton "Coach" (PourCoach Set.empty) "📋"
            , roleButton "Vestiaire" (PourVestiaire 0) "🚪"
            , roleButton "Buvette" PourBuvette "☕"
            ]
        ]


roleButton : String -> UserContext -> String -> Html Msg
roleButton label ctx icon =
    button
        [ class "flex flex-col items-center justify-center p-8 bg-gray-50 border-2 border-transparent hover:border-[#ea3a60] rounded-2xl transition-all shadow-sm group"
        , onClick (SetContexte ctx)
        ]
        [ span [ class "text-4xl mb-2 group-hover:scale-110 transition-transform" ] [ text icon ]
        , span [ class "text-xl font-bold text-gray-800" ] [ text label ]
        ]


viewStandardLayout : Model -> UserContext -> Html Msg
viewStandardLayout model ctx =
    div [ class "max-w-4xl mx-auto p-4 min-h-screen bg-white" ]
        [ h1 [ class "text-2xl font-bold text-[#ea3a60] mb-6 cursor-pointer flex items-center gap-2", onClick ResetContexte ]
            [ span [] [ text "←" ], text "CDF Synchro 2026" ]
        , viewSelection model ctx
        , div [ class "space-y-2 pb-10" ]
            (viewPlanning model ctx)
        ]


viewVestiairePrint : List Creneau -> Int -> Html Msg
viewVestiairePrint planning vNum =
    div [ class "p-10 bg-white text-black bg-white" ]
        [ button [ class "print:hidden mb-10 text-gray-500", onClick ResetContexte ] [ text "← Retour" ]
        , h1 [ class "text-6xl font-black mb-10 border-b-8 border-black pb-4" ] [ text ("VESTIAIRE " ++ String.fromInt vNum) ]
        , div [ class "space-y-8" ]
            (List.map viewVestiaireItem (getHorairesVestiaire vNum planning))
        ]


viewVestiaireItem : ViewCreneau -> Html Msg
viewVestiaireItem item =
    div [ class "flex items-baseline gap-10 border-b-2 border-gray-200 py-6" ]
        [ div [ class "text-5xl font-mono font-bold" ] [ text item.time ]
        , div []
            [ div [ class "text-4xl font-bold" ] [ text item.name ]
            , div [ class "text-2xl" ] [ text item.category ]
            ]
        ]


viewSelection : Model -> UserContext -> Html Msg
viewSelection model ctx =
    let
        equipes =
            getEquipes model.planning

        vestiaires =
            getVestiaires model.planning
    in
    case ctx of
        PourPatineur _ ->
            div [ class "mb-6" ]
                [ label [ class "block text-sm font-medium text-gray-700 mb-2" ] [ text "Sélectionner une équipe :" ]
                , select
                    [ class "block w-full text-lg p-3 border border-gray-300 rounded-xl focus:ring-[#ea3a60] focus:border-[#ea3a60]"
                    , onChange SelectEquipe
                    ]
                    (option [ value "" ] [ text "-- Sélection --" ]
                        :: List.map (\eq -> option [ value eq ] [ text eq ]) equipes
                    )
                ]

        PourCoach set ->
            div [ class "mb-6" ]
                [ label [ class "block text-sm font-medium text-gray-700 mb-2" ] [ text "Sélectionner les équipes :" ]
                , div [ class "grid grid-cols-2 gap-2" ]
                    (List.map (\eq -> viewCheckbox eq (Set.member eq set)) equipes)
                ]

        PourVestiaire _ ->
            div [ class "mb-6" ]
                [ label [ class "block text-sm font-medium text-gray-700 mb-2" ] [ text "Sélectionner un vestiaire :" ]
                , select
                    [ class "block w-full text-lg p-3 border border-gray-300 rounded-xl focus:ring-[#ea3a60] focus:border-[#ea3a60]"
                    , onChange SelectVestiaire
                    ]
                    (option [ value "" ] [ text "-- Sélection --" ]
                        :: List.map (\v -> option [ value (String.fromInt v) ] [ text ("Vestiaire " ++ String.fromInt v) ]) vestiaires
                    )
                ]

        _ ->
            text ""


viewCheckbox : String -> Bool -> Html Msg
viewCheckbox name isChecked =
    label
        [ class
            ("flex items-center gap-2 p-3 border rounded-xl cursor-pointer transition-colors "
                ++ (if isChecked then
                        "bg-[#ea3a60] text-white border-[#ea3a60]"

                    else
                        "bg-gray-50 text-gray-700"
                   )
            )
        ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , onCheck (\_ -> ToggleEquipeCoach name)
            , class "hidden"
            ]
            []
        , span [ class "text-base font-semibold" ] [ text name ]
        ]


viewPlanning : Model -> UserContext -> List (Html Msg)
viewPlanning model ctx =
    case ctx of
        PourPatineur "" ->
            [ div [ class "text-center py-10 text-gray-500" ] [ text "Veuillez sélectionner une équipe." ] ]

        PourPatineur teamName ->
            List.map viewCreneau (getHorairesPatineur teamName model.planning)

        PourCoach set ->
            if Set.isEmpty set then
                [ div [ class "text-center py-10 text-gray-500" ] [ text "Veuillez sélectionner au moins une équipe." ] ]

            else
                List.map viewCreneau (getHorairesCoach set model.planning)

        PourBuvette ->
            List.map viewBuvetteCreneau (getHorairesBuvette model.planning)

        _ ->
            []


viewCreneau : ViewCreneau -> Html Msg
viewCreneau creneau =
    div [ class "flex items-center gap-4 p-4 bg-white border border-gray-100 rounded-2xl shadow-sm mb-2" ]
        [ div [ class "w-16 font-mono text-lg font-bold text-gray-600" ] [ text creneau.time ]
        , div [ class "flex-1" ]
            [ div [ class "font-bold text-gray-800 text-lg" ] [ text creneau.name ]
            , if String.isEmpty creneau.category then
                text ""

              else
                div [ class "text-sm text-gray-500" ] [ text creneau.category ]
            ]
        ]


viewBuvetteCreneau : ViewCreneau -> Html Msg
viewBuvetteCreneau creneau =
    div [ class "flex items-center gap-4 p-4 bg-red-50 border-2 border-[#ea3a60] rounded-2xl shadow-sm mb-3 animate-pulse" ]
        [ div [ class "w-16 font-mono text-xl font-bold text-[#ea3a60]" ] [ text creneau.time ]
        , div [ class "flex-1" ]
            [ div [ class "font-black text-[#ea3a60] text-xl uppercase" ] [ text creneau.name ]
            , div [ class "text-sm font-semibold text-red-500" ] [ text "RUSH PRÉVU" ]
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
