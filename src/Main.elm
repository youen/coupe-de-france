port module Main exposing (Msg(..), main, update)

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
    | SelectVestiaire Int
    | Print
    | SetContexte UserContext
    | ResetContexte


port print : () -> Cmd msg


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

        SelectVestiaire vNum ->
            ( { model | contexte = Just (PourVestiaire vNum) }, Cmd.none )

        Print ->
            ( model, print () )

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
            viewStandardLayout model ctx


viewRoleSelection : Html Msg
viewRoleSelection =
    div [ class "min-h-screen bg-slate-50 flex flex-col items-center justify-center p-6 relative overflow-hidden font-sans" ]
        [ div [ class "absolute -top-20 -left-20 w-64 h-64 bg-[#ea3a60]/10 rounded-full blur-3xl" ] []
        , div [ class "absolute -bottom-20 -right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" ] []
        , div [ class "z-10 text-center mb-12" ]
            [ h1 [ class "text-5xl font-black gradient-text mb-4 tracking-tight" ] [ text "CDF Synchro 2026" ]
            , p [ class "text-slate-500 font-medium" ] [ text "Choisissez votre accès au planning" ]
            ]
        , div [ class "z-10 grid grid-cols-1 md:grid-cols-2 gap-6 w-full max-w-3xl" ]
            [ roleButton "Patineur" (PourPatineur "") "⛸️" "Consultez vos horaires personnels"
            , roleButton "Coach" (PourCoach Set.empty) "📋" "Gérez plusieurs équipes simultanément"
            , roleButton "Vestiaire" (PourVestiaire 0) "🚪" "Impression pour les portes des vestiaires"
            , roleButton "Buvette" PourBuvette "☕" "Anticipez les rushs de surfaçage"
            ]
        ]


roleButton : String -> UserContext -> String -> String -> Html Msg
roleButton label ctx icon desc =
    button
        [ class "group relative flex items-center p-6 bg-white border border-slate-200 rounded-3xl transition-all duration-300 hover:border-[#ea3a60] hover:shadow-2xl hover:shadow-[#ea3a60]/10 active:scale-95 overflow-hidden"
        , onClick (SetContexte ctx)
        ]
        [ div [ class "flex-shrink-0 w-16 h-16 bg-slate-50 rounded-2xl flex items-center justify-center text-3xl group-hover:bg-[#ea3a60]/10 transition-colors mr-6" ] [ text icon ]
        , div [ class "text-left" ]
            [ div [ class "text-xl font-bold text-slate-800" ] [ text label ]
            , div [ class "text-sm text-slate-500" ] [ text desc ]
            ]
        , div [ class "absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-transparent to-slate-50 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" ] []
        ]


viewStandardLayout : Model -> UserContext -> Html Msg
viewStandardLayout model ctx =
    div [ class "min-h-screen bg-slate-50" ]
        [ -- Sticky Header
          header [ class "sticky top-0 z-30 bg-white/80 backdrop-blur-md border-b border-slate-200 px-4 py-3 print:hidden" ]
            [ div [ class "max-w-4xl mx-auto flex items-center justify-between" ]
                [ button [ class "flex items-center gap-2 text-slate-600 hover:text-[#ea3a60] font-bold transition-colors", onClick ResetContexte ]
                    [ span [ class "text-xl" ] [ text "←" ], text "Retour" ]
                , div [ class "flex items-center gap-4" ]
                    [ case ctx of
                        PourVestiaire n ->
                            if n > 0 then
                                button [ class "hidden md:flex items-center gap-2 px-4 py-1.5 bg-[#ea3a60] text-white rounded-full font-bold text-sm transition-all hover:scale-105 active:scale-95", onClick Print ]
                                    [ text "🖨️ Imprimer le planning" ]

                            else
                                text ""

                        _ ->
                            text ""
                    , div [ class "font-black text-xl gradient-text" ] [ text "CDF 2026" ]
                    ]
                ]
            ]
        , main_ [ class "max-w-4xl mx-auto p-4 md:p-6" ]
            [ div [ class "hidden print:block mb-8" ]
                [ case ctx of
                    PourVestiaire n ->
                        div [ class "text-center" ]
                            [ h1 [ class "text-6xl font-black uppercase mb-2" ] [ text "VESTIAIRE" ]
                            , div [ class "text-9xl font-black" ] [ text (String.fromInt n) ]
                            ]

                    _ ->
                        text ""
                ]
            , div [ class "print:hidden" ] [ viewSelection model ctx ]
            , div [ class "space-y-4 pb-20" ]
                (viewPlanning model ctx)
            , div [ class "hidden print:block text-center text-2xl font-bold mt-10 border-t-4 border-black pt-8" ]
                [ text "COUPE DE FRANCE 2026" ]
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
            div [ class "mb-8 bg-white p-6 rounded-3xl shadow-sm border border-slate-200" ]
                [ label [ class "block text-xs font-black text-slate-400 uppercase tracking-widest mb-3" ] [ text "Équipe" ]
                , div [ class "relative" ]
                    [ select
                        [ class "block w-full text-lg font-bold p-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-[#ea3a60] appearance-none cursor-pointer"
                        , onChange SelectEquipe
                        ]
                        (option [ value "" ] [ text "-- Choisissez votre équipe --" ]
                            :: List.map (\eq -> option [ value eq ] [ text eq ]) equipes
                        )
                    , div [ class "absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400" ] [ text "▼" ]
                    ]
                ]

        PourCoach set ->
            div [ class "mb-8 bg-white p-6 rounded-3xl shadow-sm border border-slate-200" ]
                [ label [ class "block text-xs font-black text-slate-400 uppercase tracking-widest mb-4" ] [ text "Équipes suivies" ]
                , div [ class "grid grid-cols-2 md:grid-cols-3 gap-3" ]
                    (List.map (\eq -> viewCheckbox eq (Set.member eq set)) equipes)
                ]

        PourVestiaire vNum ->
            if vNum == 0 then
                div [ class "grid grid-cols-2 md:grid-cols-4 gap-4" ]
                    (List.map
                        (\v ->
                            button
                                [ class "p-8 bg-white border-2 border-slate-100 rounded-3xl hover:border-[#ea3a60] transition-all group active:scale-95 shadow-sm"
                                , onClick (SelectVestiaire v)
                                ]
                                [ div [ class "text-xs font-black text-slate-400 uppercase tracking-widest mb-1" ] [ text "Vestiaire" ]
                                , div [ class "text-4xl font-black text-slate-800 group-hover:text-[#ea3a60] transition-colors" ] [ text (String.fromInt v) ]
                                ]
                        )
                        vestiaires
                    )

            else
                text ""

        PourBuvette ->
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

        PourVestiaire vNum ->
            if vNum == 0 then
                []

            else
                List.map viewCreneau (getHorairesVestiaire vNum model.planning)


viewCreneau : ViewCreneau -> Html Msg
viewCreneau creneau =
    div [ class "group flex items-center gap-6 p-5 bg-white border border-slate-100 rounded-[2rem] shadow-sm hover:shadow-md transition-all duration-300" ]
        [ div [ class "flex-shrink-0 w-20 flex flex-col items-center justify-center border-r border-slate-100 pr-6" ]
            [ div [ class "text-xl font-black text-slate-800 font-mono tracking-tight" ] [ text creneau.time ]
            , div [ class "text-[10px] font-black text-slate-400 uppercase tracking-widest" ] [ text "Heure" ]
            ]
        , div [ class "flex-1" ]
            [ div [ class "font-black text-slate-800 text-lg leading-tight mb-1 group-hover:text-[#ea3a60] transition-colors" ] [ text creneau.name ]
            , if String.isEmpty creneau.category then
                text ""

              else
                div [ class "inline-block px-2 py-0.5 bg-slate-100 text-slate-500 text-[10px] font-bold rounded-md uppercase tracking-wider" ] [ text creneau.category ]
            ]
        , div [ class "w-2 h-12 bg-slate-100 rounded-full group-hover:bg-[#ea3a60]/20 transition-colors" ] []
        ]


viewBuvetteCreneau : ViewCreneau -> Html Msg
viewBuvetteCreneau creneau =
    div [ class "relative group flex items-center gap-6 p-6 bg-white border-2 border-red-100 rounded-[2rem] shadow-sm overflow-hidden" ]
        [ div [ class "absolute inset-0 bg-red-50/50 animate-pulse pointer-events-none" ] []
        , div [ class "z-10 flex-shrink-0 w-20 flex flex-col items-center justify-center border-r border-red-100 pr-6" ]
            [ div [ class "text-2xl font-black text-red-600 font-mono tracking-tight" ] [ text creneau.time ]
            , div [ class "text-[10px] font-black text-red-400 uppercase tracking-widest" ] [ text "Rush" ]
            ]
        , div [ class "z-10 flex-1" ]
            [ div [ class "font-black text-slate-800 text-xl uppercase leading-tight mb-1" ] [ text creneau.name ]
            , div [ class "inline-flex items-center gap-1.5 text-red-500 text-[10px] font-black uppercase tracking-[0.2em]" ]
                [ div [ class "w-2 h-2 bg-red-500 rounded-full animate-ping" ] []
                , text "Attention Rush"
                ]
            ]
        , div [ class "z-10 w-2 h-16 bg-red-500 rounded-full" ] []
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
