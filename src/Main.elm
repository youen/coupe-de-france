port module Main exposing (Msg(..), init, main, update)

import Benevoles
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Json.Decode as Decode
import Model exposing (..)
import Set
import Task
import Time


type Msg
    = SelectEquipe String
    | ToggleEquipeCoach String
    | ToggleMissionBenevole String
    | SelectVestiaire Int
    | Print
    | SetContexte UserContext
    | ResetContexte
    | Tick Time.Posix
    | AdjustTimeZone Time.Zone
    | SetDemoMode Bool
    | SetDemoTime Int
    | GoBack
    | GoToRecap
    | ConfirmMissions
    | ExportMission Benevoles.Mission
    | ExportAllMissions


port print : () -> Cmd msg


port saveBenevoleSelection : List String -> Cmd msg


port saveTeamsSelection : List String -> Cmd msg


port savePatineurTeam : String -> Cmd msg


port exportCalendar : List CalendarEvent -> Cmd msg


type alias CalendarEvent =
    { title : String
    , day : Maybe String -- YYYY-MM-DD
    , startTime : Maybe String -- HH:mm
    , endTime : Maybe String -- HH:mm
    , description : String
    , location : String
    }


type alias FlagsData =
    { planning : List Creneau
    , benevoles : Maybe Benevoles.Root
    , selectedMissions : List String
    , selectedTeams : List String
    , selectedPatineurTeam : String
    }


flagsDecoder : Decode.Decoder FlagsData
flagsDecoder =
    Decode.succeed FlagsData
        |> andMap (Decode.field "planningData" rootDecoder)
        |> andMap (Decode.maybe (Decode.field "benevolesData" Benevoles.rootDecoder))
        |> andMap (Decode.oneOf [ Decode.field "selectedMissions" (Decode.list Decode.string), Decode.succeed [] ])
        |> andMap (Decode.oneOf [ Decode.field "selectedTeams" (Decode.list Decode.string), Decode.succeed [] ])
        |> andMap (Decode.oneOf [ Decode.field "selectedPatineurTeam" Decode.string, Decode.succeed "" ])


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        decodedFlags =
            Decode.decodeValue flagsDecoder flags
                |> Result.withDefault { planning = [], benevoles = Nothing, selectedMissions = [], selectedTeams = [], selectedPatineurTeam = "" }

        initialContext =
            if List.isEmpty decodedFlags.selectedMissions && List.isEmpty decodedFlags.selectedTeams && decodedFlags.selectedPatineurTeam == "" then
                Nothing

            else
                Just MonPlanning
    in
    ( { planning = decodedFlags.planning
      , benevoles = decodedFlags.benevoles
      , selectedTeams = Set.fromList decodedFlags.selectedTeams
      , selectedMissions = Set.fromList decodedFlags.selectedMissions
      , selectedPatineurTeam = decodedFlags.selectedPatineurTeam
      , contexte = initialContext
      , currentTime = Time.millisToPosix 0
      , zone = Time.utc
      , isDemoMode = False
      , demoTimeMinutes = 420
      }
    , Task.perform AdjustTimeZone Time.here
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectEquipe name ->
            ( { model | selectedPatineurTeam = name }, savePatineurTeam name )

        ToggleEquipeCoach name ->
            let
                newSet =
                    if Set.member name model.selectedTeams then
                        Set.remove name model.selectedTeams

                    else
                        Set.insert name model.selectedTeams
            in
            ( { model | selectedTeams = newSet }, saveTeamsSelection (Set.toList newSet) )

        ToggleMissionBenevole name ->
            let
                newSet =
                    if Set.member name model.selectedMissions then
                        Set.remove name model.selectedMissions

                    else
                        Set.insert name model.selectedMissions
            in
            ( { model | selectedMissions = newSet }, saveBenevoleSelection (Set.toList newSet) )

        SelectVestiaire vNum ->
            ( { model | contexte = Just (PourVestiaire vNum) }, Cmd.none )

        Print ->
            ( model, print () )

        SetContexte ctx ->
            ( { model | contexte = Just ctx }, Cmd.none )

        ResetContexte ->
            ( { model | contexte = Nothing }, Cmd.none )

        Tick newTime ->
            ( { model | currentTime = newTime }, Cmd.none )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Cmd.none )

        SetDemoMode enabled ->
            ( { model | isDemoMode = enabled }, Cmd.none )

        SetDemoTime minutes ->
            ( { model | demoTimeMinutes = minutes }, Cmd.none )

        GoBack ->
            case model.contexte of
                Just (PourVestiaire vNum) ->
                    if vNum == 0 then
                        ( { model | contexte = Nothing }, Cmd.none )

                    else
                        ( { model | contexte = Just (PourVestiaire 0) }, Cmd.none )

                Just RecapBenevole ->
                    ( { model | contexte = Just PourBenevole }, Cmd.none )

                _ ->
                    ( { model | contexte = Nothing }, Cmd.none )

        GoToRecap ->
            ( { model | contexte = Just RecapBenevole }, Cmd.none )

        ConfirmMissions ->
            ( { model | contexte = Just MonPlanning }, Cmd.none )

        ExportMission mission ->
            ( model
            , exportCalendar
                [ { title = mission.mission
                  , day = mission.jour
                  , startTime = mission.debut
                  , endTime = mission.fin
                  , description = mission.description
                  , location = mission.lieu
                  }
                ]
            )

        ExportAllMissions ->
            let
                missions =
                    model.benevoles
                        |> Maybe.map .postesBenevoles
                        |> Maybe.withDefault []
                        |> List.filter (\m -> Set.member m.mission model.selectedMissions)

                events =
                    missions
                        |> List.map
                            (\m ->
                                { title = m.mission
                                , day = m.jour
                                , startTime = m.debut
                                , endTime = m.fin
                                , description = m.description
                                , location = m.lieu
                                }
                            )
            in
            ( model, exportCalendar events )


view : Model -> Html Msg
view model =
    div []
        [ case model.contexte of
            Nothing ->
                viewRoleSelection

            Just ctx ->
                viewStandardLayout model ctx
        , viewDemoMode model
        ]


viewRoleSelection : Html Msg
viewRoleSelection =
    div [ class "min-h-screen bg-white flex flex-col items-center justify-center p-6 relative overflow-hidden" ]
        [ div [ class "absolute -top-20 -left-20 w-64 h-64 bg-[#ea3a60]/5 rounded-full blur-3xl" ] []
        , div [ class "absolute -bottom-20 -right-20 w-96 h-96 bg-[#171717]/5 rounded-full blur-3xl" ] []
        , div [ class "z-10 text-center mb-12" ]
            [ h1 [ class "text-6xl font-black gradient-text mb-4 tracking-tight" ] [ text "CDF Synchro 2026" ]
            , p [ class "text-[#1d1d1d] font-medium opacity-60" ] [ text "Choisissez votre accès au planning" ]
            ]
        , div [ class "z-10 grid grid-cols-1 md:grid-cols-2 gap-6 w-full max-w-3xl" ]
            [ roleButton "Mon Planning" MonPlanning "📅" "Planning personnel regroupant vos choix"
            , roleButton "Patineur" PourPatineur "⛸️" "Horaires personnels (Nom d'équipe)"
            , roleButton "Coach / Parent / Supporter" PourCoach "📋" "Suivez une ou plusieurs équipes"
            , roleButton "Bénévole" PourBenevole "🙋" "Sélectionnez vos missions"
            , roleButton "Vestiaire" (PourVestiaire 0) "🚪" "Horaires par numéro de vestiaire"
            , roleButton "Buvette" PourBuvette "☕" "Alerte rushs pour la restauration"
            ]
        ]


roleButton : String -> UserContext -> String -> String -> Html Msg
roleButton label ctx icon desc =
    button
        [ class "group relative flex items-center p-6 bg-white border border-slate-100 rounded-3xl transition-all duration-300 hover:border-[#ea3a60] hover:shadow-2xl hover:shadow-[#ea3a60]/5 active:scale-95 overflow-hidden"
        , onClick (SetContexte ctx)
        ]
        [ div [ class "flex-shrink-0 w-16 h-16 bg-slate-50 rounded-2xl flex items-center justify-center text-3xl group-hover:bg-[#ea3a60]/10 transition-colors mr-6" ] [ text icon ]
        , div [ class "text-left" ]
            [ div [ class "text-xl font-bold text-[#1d1d1d]" ] [ text label ]
            , div [ class "text-sm text-slate-400" ] [ text desc ]
            ]
        , div [ class "absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-transparent to-slate-50/30 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" ] []
        ]


viewStandardLayout : Model -> UserContext -> Html Msg
viewStandardLayout model ctx =
    let
        contextClass =
            case ctx of
                PourVestiaire _ ->
                    "context-vestiaire"

                PourPatineur ->
                    "context-patineur"

                PourCoach ->
                    "context-coach"

                PourBenevole ->
                    "context-benevole"

                RecapBenevole ->
                    "context-benevole"

                MonPlanning ->
                    "context-mon-planning"

                PourBuvette ->
                    "context-buvette"
    in
    div [ class ("min-h-screen bg-white print:p-[10mm] " ++ contextClass) ]
        [ -- Sticky Header
          header [ class "sticky top-0 z-30 bg-[#171717] border-b border-black/10 px-4 py-3 shadow-xl print:hidden" ]
            [ div [ class "max-w-4xl mx-auto flex items-center justify-between" ]
                [ button [ class "flex items-center gap-2 text-white/70 hover:text-[#ea3a60] font-bold transition-colors", onClick GoBack ]
                    [ span [ class "text-xl" ] [ text "←" ], text "Retour" ]
                , div [ class "flex items-center gap-4" ]
                    [ case ctx of
                        PourVestiaire n ->
                            if n > 0 then
                                button [ class "btn-primary !py-1 text-xs", onClick Print ]
                                    [ text "🖨️ IMPRIMER" ]

                            else
                                text ""

                        _ ->
                            text ""
                    , div [ class "flex flex-col items-end" ]
                        [ div [ class "font-black text-xl text-[#ea3a60] tracking-wider" ] [ text "CDF 2026" ] ]
                    ]
                ]
            ]
        , main_ [ class "max-w-4xl mx-auto p-4 md:p-6 print:p-0 print:max-w-full" ]
            [ div [ class "hidden print:block mb-2" ]
                [ case ctx of
                    PourVestiaire n ->
                        div [ class "text-center border-2 border-black p-2 mb-2" ]
                            [ h1 [ class "text-lg font-black uppercase tracking-wider inline-block mr-2" ] [ text "VESTIAIRE" ]
                            , div [ class "text-2xl font-black inline-block" ] [ text (String.fromInt n) ]
                            ]

                    _ ->
                        text ""
                ]
            , div [ class "print:hidden" ] [ viewSelection model ctx ]
            , div [ class "space-y-4 print:space-y-0.5 pb-20 print:pb-0" ]
                (viewPlanning model ctx)
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
        PourPatineur ->
            div [ class "mb-8 bg-white p-6 rounded-3xl shadow-sm border border-slate-200" ]
                [ label [ class "block text-xs font-black text-slate-400 uppercase tracking-widest mb-3" ] [ text "Équipe" ]
                , div [ class "relative" ]
                    [ select
                        [ class "block w-full text-lg font-bold p-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#ea3a60] appearance-none cursor-pointer text-[#1d1d1d]"
                        , onChange SelectEquipe
                        , value model.selectedPatineurTeam
                        ]
                        (option [ value "", selected (model.selectedPatineurTeam == "") ] [ text "-- Choisissez votre équipe --" ]
                            :: List.map (\eq -> option [ value eq, selected (eq == model.selectedPatineurTeam) ] [ text eq ]) equipes
                        )
                    , div [ class "absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400" ] [ text "▼" ]
                    ]
                ]

        PourCoach ->
            div [ class "space-y-6" ]
                [ div [ class "bg-white p-6 rounded-3xl shadow-sm border border-slate-200" ]
                    [ label [ class "block text-xs font-black text-slate-400 uppercase tracking-widest mb-4" ] [ text "Équipes suivies" ]
                    , div [ class "grid grid-cols-1 md:grid-cols-3 gap-3" ]
                        (List.map (\eq -> viewCheckbox eq (Set.member eq model.selectedTeams)) equipes)
                    ]
                , div [ class "p-6 bg-[#ea3a60]/5 rounded-3xl border border-[#ea3a60]/10" ]
                    [ div [ class "flex items-center gap-3 mb-2" ]
                        [ span [ class "text-xl" ] [ text "📅" ]
                        , h3 [ class "text-sm font-black text-[#ea3a60] uppercase tracking-wider" ] [ text "Info Planning" ]
                        ]
                    , p [ class "text-sm text-slate-600 font-medium leading-relaxed" ]
                        [ text "Les horaires (vestiaire, piste, kiss & cry) des équipes sélectionnées apparaîtront automatiquement dans votre onglet "
                        , span [ class "font-black text-slate-800" ] [ text "Mon Planning" ]
                        , text "."
                        ]
                    ]
                ]

        PourVestiaire vNum ->
            if vNum == 0 then
                div [ class "grid grid-cols-2 md:grid-cols-4 gap-4" ]
                    (List.map
                        (\v ->
                            button
                                [ class "p-8 bg-white border border-slate-100 rounded-3xl hover:border-[#ea3a60] transition-all group active:scale-95 shadow-sm"
                                , onClick (SelectVestiaire v)
                                ]
                                [ div [ class "text-xs font-black text-slate-400 uppercase tracking-widest mb-1" ] [ text "Vestiaire" ]
                                , div [ class "text-4xl font-black text-[#1d1d1d] group-hover:text-[#ea3a60] transition-colors" ] [ text (String.fromInt v) ]
                                ]
                        )
                        vestiaires
                    )

            else
                div [ class "mb-8 flex items-center justify-center p-6 bg-white rounded-3xl border border-slate-100 shadow-sm" ]
                    [ div [ class "text-center" ]
                        [ div [ class "text-xs font-black text-slate-400 uppercase tracking-widest mb-1" ] [ text "Vestiaire" ]
                        , div [ class "text-4xl font-black text-[#ea3a60]" ] [ text (String.fromInt vNum) ]
                        ]
                    ]

        PourBuvette ->
            text ""

        PourBenevole ->
            let
                set =
                    model.selectedMissions

                missions =
                    model.benevoles
                        |> Maybe.map .postesBenevoles
                        |> Maybe.withDefault []

                periodes =
                    Benevoles.getPeriodes missions

                nbSelected =
                    Set.size set
            in
            div [ class "flex flex-col gap-8" ]
                (div [ class "bg-[#ea3a60]/5 rounded-[2.5rem] p-6 border border-[#ea3a60]/10 mb-2" ]
                    [ div [ class "flex items-center gap-3 mb-4" ]
                        [ span [ class "text-xl" ] [ text "👋" ]
                        , h2 [ class "text-sm font-black text-[#ea3a60] uppercase tracking-wider" ] [ text "Comment ça marche ?" ]
                        ]
                    , div [ class "grid grid-cols-1 gap-4" ]
                        [ div [ class "flex items-start gap-4" ]
                            [ div [ class "flex-shrink-0 w-6 h-6 bg-[#ea3a60] text-white text-xs font-black rounded-md flex items-center justify-center mt-0.5" ] [ text "1" ]
                            , div [ class "text-sm text-slate-600 font-medium leading-relaxed" ]
                                [ text "Parcourez la liste et "
                                , span [ class "font-black text-slate-800" ] [ text "cochez les cases" ]
                                , text " pour sélectionner vos missions."
                                ]
                            ]
                        , div [ class "flex items-start gap-4" ]
                            [ div [ class "flex-shrink-0 w-6 h-6 bg-[#ea3a60] text-white text-xs font-black rounded-md flex items-center justify-center mt-0.5" ] [ text "2" ]
                            , div [ class "text-sm text-slate-600 font-medium leading-relaxed" ]
                                [ text "N'oubliez pas d'"
                                , span [ class "font-black text-slate-800" ] [ text "ajouter les horaires" ]
                                , text " dans votre agenda via l'icône "
                                , span [ class "font-black text-slate-800" ] [ text "📅" ]
                                , text "."
                                ]
                            ]
                        , div [ class "flex items-start gap-4" ]
                            [ div [ class "flex-shrink-0 w-6 h-6 bg-[#ea3a60] text-white text-xs font-black rounded-md flex items-center justify-center mt-0.5" ] [ text "3" ]
                            , div [ class "text-sm text-slate-600 font-medium leading-relaxed" ]
                                [ text "Une fois votre sélection finie, cliquez sur "
                                , span [ class "font-black text-slate-800" ] [ text "Voir le récapitulatif" ]
                                , text " pour confirmer par email."
                                ]
                            ]
                        ]
                    ]
                    :: List.map
                        (\periode ->
                            let
                                periodeMissions =
                                    missions
                                        |> List.filter (\m -> m.periode == periode)
                            in
                            div [ class "bg-slate-50/50 p-6 rounded-[2.5rem] border border-slate-100" ]
                                [ div [ class "flex items-center gap-3 mb-6 px-2" ]
                                    [ span [ class "text-sm font-black text-slate-400 uppercase tracking-widest" ] [ text periode ]
                                    , div [ class "h-px flex-1 bg-slate-200/50" ] []
                                    ]
                                , div [ class "grid grid-cols-1 md:grid-cols-2 gap-3" ]
                                    (List.map (\m -> viewMissionCheckbox m (Set.member m.mission set)) periodeMissions)
                                ]
                        )
                        periodes
                    ++ [ div [ class "mt-4 print:hidden" ]
                            [ button
                                [ class
                                    ("flex items-center justify-center gap-3 w-full py-5 rounded-2xl font-black shadow-lg transition-all active:scale-95 text-lg "
                                        ++ (if nbSelected > 0 then
                                                "bg-[#ea3a60] text-white hover:bg-[#c42d50] cursor-pointer"

                                            else
                                                "bg-slate-100 text-slate-400 cursor-not-allowed"
                                           )
                                    )
                                , onClick GoToRecap
                                , Html.Attributes.disabled (nbSelected == 0)
                                ]
                                [ span [ class "text-xl" ] [ text "📋" ]
                                , text
                                    (if nbSelected > 0 then
                                        "Voir le récapitulatif ("
                                            ++ String.fromInt nbSelected
                                            ++ " mission"
                                            ++ (if nbSelected > 1 then
                                                    "s"

                                                else
                                                    ""
                                               )
                                            ++ ")"

                                     else
                                        "Sélectionnez des missions pour continuer"
                                    )
                                ]
                            ]
                       ]
                )

        RecapBenevole ->
            let
                missions =
                    model.benevoles
                        |> Maybe.map .postesBenevoles
                        |> Maybe.withDefault []

                selectedMissions =
                    Benevoles.getMissionsSelectionnees model.selectedMissions missions
            in
            div [ class "flex flex-col gap-6" ]
                [ div [ class "bg-[#ea3a60]/5 rounded-[2.5rem] p-6 border border-[#ea3a60]/10" ]
                    [ div [ class "flex items-center gap-3 mb-4" ]
                        [ span [ class "text-2xl" ] [ text "📋" ]
                        , h2 [ class "text-lg font-black text-[#ea3a60] uppercase tracking-wider" ] [ text "Récapitulatif" ]
                        ]
                    , p [ class "text-sm text-slate-500 font-medium mb-6" ]
                        [ text "Vérifiez vos missions avant de confirmer. Un email s'ouvrira dans votre application de messagerie." ]
                    , div [ class "space-y-3 mb-6" ]
                        (if List.isEmpty selectedMissions then
                            [ div [ class "text-center py-8 text-slate-400" ]
                                [ div [ class "text-3xl mb-2" ] [ text "😕" ]
                                , p [ class "font-medium" ] [ text "Aucune mission sélectionnée." ]
                                ]
                            ]

                         else
                            List.map viewRecapMissionItem selectedMissions
                        )
                    , a
                        [ href (buildMailtoUrl selectedMissions)
                        , target "_blank"
                        , class "flex items-center justify-center gap-3 w-full py-5 bg-[#ea3a60] text-white rounded-2xl font-black shadow-lg hover:bg-[#c42d50] transition-all active:scale-95 text-lg"
                        , Html.Attributes.attribute "id" "btn-confirmer-email"
                        , onClickPreserveDefault ConfirmMissions
                        ]
                        [ span [ class "text-xl" ] [ text "✉️" ]
                        , text "CONFIRMER PAR EMAIL"
                        ]
                    , p [ class "text-[10px] text-center text-slate-400 mt-2 font-medium" ] [ text "Envoie votre sélection par mail au responsable" ]
                    , button
                        [ class "mt-4 flex items-center justify-center gap-2 w-full py-3 bg-white border border-slate-200 text-slate-600 rounded-2xl font-bold hover:border-slate-300 transition-all active:scale-95"
                        , onClick GoBack
                        ]
                        [ span [] [ text "←" ]
                        , text "Retour à la sélection"
                        ]
                    ]
                ]

        MonPlanning ->
            text ""


viewMissionCheckbox : Benevoles.Mission -> Bool -> Html Msg
viewMissionCheckbox mission isChecked =
    let
        activeClasses =
            if isChecked then
                "border-[#ea3a60] bg-[#ea3a60]/5 shadow-sm"

            else
                "border-slate-100 bg-white hover:border-slate-300"

        iconClasses =
            if isChecked then
                "bg-[#ea3a60] text-white"

            else
                "bg-slate-50 text-slate-400 group-hover:bg-slate-100"
    in
    label
        [ class ("group relative flex items-start gap-4 p-4 rounded-2xl border-2 cursor-pointer transition-all duration-200 " ++ activeClasses)
        ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , onCheck (\_ -> ToggleMissionBenevole mission.mission)
            , class "peer sr-only"
            ]
            []
        , div
            [ class ("flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center text-xl transition-colors " ++ iconClasses) ]
            [ text mission.icone ]
        , div [ class "flex-1 min-w-0" ]
            [ div [ class "flex items-center justify-between gap-2 mb-1" ]
                [ div
                    [ class
                        ("font-black text-sm truncate "
                            ++ (if isChecked then
                                    "text-[#ea3a60]"

                                else
                                    "text-slate-700"
                               )
                        )
                    ]
                    [ text mission.mission ]
                , div
                    [ class
                        ("w-5 h-5 rounded-sm border-2 flex items-center justify-center transition-colors flex-shrink-0 "
                            ++ (if isChecked then
                                    "border-[#ea3a60] bg-[#ea3a60]"

                                else
                                    "border-slate-300 bg-white"
                               )
                        )
                    ]
                    [ if isChecked then
                        span [ class "text-white text-xs" ] [ text "✓" ]

                      else
                        text ""
                    ]
                ]
            , div [ class "flex items-center gap-2 mb-1" ]
                [ if String.contains "REZE" (String.toUpper mission.lieu) then
                    span [ class "px-1.5 py-0.5 bg-purple-100 text-purple-600 text-[8px] font-black rounded uppercase" ] [ text "📍 Rezé" ]

                  else
                    span [ class "px-1.5 py-0.5 bg-blue-50 text-blue-500 text-[8px] font-black rounded uppercase" ] [ text "📍 Petit Port" ]
                , let
                    timeRange =
                        case ( mission.debut, mission.fin ) of
                            ( Just s, Just e ) ->
                                s ++ " - " ++ e

                            ( Just s, Nothing ) ->
                                s

                            ( Nothing, Just e ) ->
                                "?? - " ++ e

                            _ ->
                                ""
                  in
                  if timeRange == "" then
                    text ""

                  else
                    span [ class "px-1.5 py-0.5 bg-slate-100 text-slate-600 text-[8px] font-black rounded uppercase" ] [ text ("🕒 " ++ timeRange) ]
                ]
            , div [ class "text-[10px] font-medium text-slate-400" ] [ text mission.description ]
            ]
        ]


viewCheckbox : String -> Bool -> Html Msg
viewCheckbox name isChecked =
    label
        [ class
            ("flex items-center gap-2 p-3 border rounded-xl cursor-pointer transition-colors "
                ++ (if isChecked then
                        "bg-[#ea3a60] text-white border-[#ea3a60]"

                    else
                        "bg-white text-gray-700 border-slate-100"
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
    let
        realMinutes =
            posixToMinutes model.zone model.currentTime

        nowMinutes =
            getEffectiveMinutes model realMinutes

        isCompetitionDay =
            Time.toYear model.zone model.currentTime
                == 2026
                && Time.toMonth model.zone model.currentTime
                == Time.Apr
                && Time.toDay model.zone model.currentTime
                == 4

        shouldMask =
            model.isDemoMode || isCompetitionDay

        relevantPlanning =
            if shouldMask then
                model.planning
                    |> List.filter (\c -> estEncorePertinent c nowMinutes)

            else
                model.planning
    in
    case ctx of
        PourPatineur ->
            if model.selectedPatineurTeam == "" then
                [ div [ class "text-center py-10 text-gray-500" ] [ text "Veuillez sélectionner une équipe." ] ]

            else
                getHorairesPatineur model.selectedPatineurTeam relevantPlanning
                    |> List.map (viewCreneauWithTime shouldMask nowMinutes)

        PourCoach ->
            if Set.isEmpty model.selectedTeams then
                [ div [ class "text-center py-10 text-gray-500" ] [ text "Veuillez sélectionner au moins une équipe." ] ]

            else
                getHorairesCoach model.selectedTeams relevantPlanning
                    |> List.map (viewCreneauWithTime shouldMask nowMinutes)

        PourBuvette ->
            getHorairesBuvette relevantPlanning
                |> List.map (viewBuvetteCreneau shouldMask nowMinutes)

        PourVestiaire vNum ->
            if vNum == 0 then
                []

            else
                getHorairesVestiaireGrouped vNum model.planning
                    |> List.concatMap viewVestiaireCategorie

        PourBenevole ->
            []

        RecapBenevole ->
            []

        MonPlanning ->
            let
                missions =
                    model.benevoles
                        |> Maybe.map .postesBenevoles
                        |> Maybe.withDefault []

                selectedMissions =
                    Benevoles.getMissionsSelectionnees model.selectedMissions missions
                        |> (if shouldMask then
                                List.filter (Benevoles.estMissionPertinente nowMinutes)

                            else
                                identity
                           )

                allTeams =
                    if model.selectedPatineurTeam == "" then
                        model.selectedTeams

                    else
                        Set.insert model.selectedPatineurTeam model.selectedTeams

                coachHoraires =
                    getHorairesCoach allTeams relevantPlanning

                -- Convert missions to ViewCreneau to sort them together?
                -- Or just show them in two groups? Sorting together is better.
                -- For now let's just group them for simplicity, then we can improve.
            in
            if List.isEmpty selectedMissions && List.isEmpty coachHoraires then
                [ div [ class "text-center py-10" ]
                    [ div [ class "text-4xl mb-4" ] [ text "📅" ]
                    , div [ class "text-gray-500 font-medium" ] [ text "Votre planning est vide." ]
                    , div [ class "text-sm text-gray-400 mt-2" ] [ text "Sélectionnez des missions ou des équipes pour les voir ici." ]
                    ]
                ]

            else
                List.concat
                    [ if List.isEmpty selectedMissions then
                        []

                      else
                        [ div [ class "mb-8" ]
                            [ div [ class "flex items-center justify-between mb-4 px-2" ]
                                [ h2 [ class "text-sm font-black text-slate-800 uppercase tracking-widest" ] [ text "Mes Missions" ]
                                , button [ class "text-[10px] font-black text-[#ea3a60] uppercase border-b border-[#ea3a60]/20 pb-0.5", onClick ExportAllMissions ] [ text "Tout exporter 📅" ]
                                ]
                            , div [ class "space-y-3" ] (List.map (viewBenevoleMissionItem shouldMask nowMinutes) selectedMissions)
                            ]
                        ]
                    , if List.isEmpty coachHoraires then
                        []

                      else
                        [ div [ class "mb-8" ]
                            [ div [ class "flex items-center mb-4 px-2" ]
                                [ h2 [ class "text-sm font-black text-slate-800 uppercase tracking-widest" ] [ text "Mes Équipes" ]
                                , div [ class "ml-3 h-px flex-1 bg-slate-100" ] []
                                ]
                            , div [ class "space-y-3" ] (List.map (viewCreneauWithTime shouldMask nowMinutes) coachHoraires)
                            ]
                        ]
                    ]


viewDemoMode : Model -> Html Msg
viewDemoMode model =
    div [ class "fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-4 bg-[#171717] px-6 py-3 rounded-[2rem] border border-white/10 shadow-2xl print:hidden backdrop-blur-xl" ]
        [ div [ class "flex items-center gap-2" ]
            [ span [ class "text-[10px] font-black text-white/50 uppercase tracking-widest" ] [ text "Mode Démo" ]
            , input
                [ type_ "checkbox"
                , checked model.isDemoMode
                , onCheck SetDemoMode
                , class "relative w-10 h-5 bg-white/10 rounded-full appearance-none cursor-pointer transition-colors checked:bg-[#ea3a60] before:content-[''] before:absolute before:top-1 before:left-1 before:w-3 before:h-3 before:bg-white before:rounded-full before:transition-transform checked:before:translate-x-5"
                ]
                []
            ]
        , if model.isDemoMode then
            div [ class "flex items-center gap-3" ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "420"
                    , Html.Attributes.max "1200"
                    , value (String.fromInt model.demoTimeMinutes)
                    , onInput (String.toInt >> Maybe.withDefault 420 >> SetDemoTime)
                    , class "w-32 accent-[#ea3a60]"
                    ]
                    []
                , span [ class "font-mono font-bold text-[#ea3a60] text-sm tabular-nums w-12" ]
                    [ text (formatTime { hour = model.demoTimeMinutes // 60, minute = remainderBy 60 model.demoTimeMinutes }) ]
                ]

          else
            text ""
        ]


viewCreneauWithTime : Bool -> Int -> ViewCreneau -> Html Msg
viewCreneauWithTime shouldMask nowMinutes creneau =
    let
        timeMinutes =
            viewCreneauToMinutes creneau

        isPast =
            shouldMask && nowMinutes > timeMinutes
    in
    viewCreneau nowMinutes creneau isPast


viewCreneau : Int -> ViewCreneau -> Bool -> Html Msg
viewCreneau nowMinutes creneau isPast =
    let
        isSurfacage =
            String.contains "Surfaçage" creneau.name

        sessionClass =
            case creneau.session of
                Just Competition ->
                    " border-l-[12px] border-l-[#ea3a60] bg-white"

                Just Entrainement ->
                    " border-l-[12px] border-l-slate-300 bg-slate-50/50"

                Nothing ->
                    if isSurfacage then
                        " bg-[#e0f2fe]/30 border-l-[12px] border-l-[#bae6fd]"

                    else if creneau.icon == "🏆" then
                        " bg-[#fef9c3]/30 border-l-[12px] border-l-[#fde047]"

                    else
                        " bg-white"

        baseClass =
            "group flex items-center gap-6 p-5 border rounded-[2rem] shadow-sm hover:shadow-md transition-all duration-300 print:shadow-none print:border-b print:rounded-none print:p-0.5 print:gap-2 "

        borderClass =
            "border-slate-100"

        opacityClass =
            if isPast then
                " event-past"

            else if (viewCreneauToMinutes creneau - nowMinutes) <= 10 && (viewCreneauToMinutes creneau - nowMinutes) >= 0 then
                " event-imminent"

            else
                ""

        accentClass =
            if creneau.isGlissage && not isPast then
                if creneau.session == Just Competition then
                    " text-[#ea3a60] font-black"

                else
                    " text-slate-900 font-extrabold"

            else
                " text-slate-700"
    in
    div [ class (baseClass ++ borderClass ++ opacityClass ++ sessionClass) ]
        [ div [ class "flex-shrink-0 w-20 flex flex-col items-center justify-center border-r border-slate-100 pr-6 print:w-12 print:pr-1" ]
            [ div [ class "text-xl font-black text-[#1d1d1d] font-mono tracking-tight print:text-sm" ] [ text creneau.time ]
            , div
                [ class "text-2xl mt-1 print:hidden"
                , style "transform"
                    (if creneau.flipIcon then
                        "scaleX(-1)"

                     else
                        "none"
                    )
                , style "display" "inline-block"
                ]
                [ text creneau.icon ]
            ]
        , div [ class "flex-1 flex items-baseline gap-2 overflow-hidden" ]
            [ div [ class ("text-lg leading-tight mb-1 group-hover:text-[#ea3a60] transition-colors print:text-sm print:truncate " ++ accentClass) ]
                [ text (String.toUpper creneau.name) ]
            , if String.isEmpty creneau.category then
                text ""

              else
                span [ class "inline-block px-2 py-0.5 bg-black/5 text-slate-500 text-[10px] font-bold rounded-md uppercase tracking-wider print:text-[10px] print:bg-transparent print:p-0 print:italic print:font-medium" ] [ text ("(" ++ creneau.category ++ ")") ]
            ]
        , div [ class "w-2 h-12 bg-slate-100 rounded-full group-hover:bg-[#ea3a60]/20 transition-colors print:hidden" ] []
        ]


viewVestiaireCategorie : VestiaireCategorie -> List (Html Msg)
viewVestiaireCategorie cat =
    div [ class "mt-10 mb-4 first:mt-0 print:mt-6 print:mb-2" ]
        [ div [ class "flex items-end justify-between" ]
            [ div [ class "px-4 py-1 bg-slate-800 text-white text-[10px] font-black uppercase tracking-widest rounded-lg print:bg-black print:rounded-none print:px-2" ]
                [ text cat.nom ]
            , div [ class "flex gap-4 px-4 print:gap-2 print:px-3" ]
                [ viewMilestoneHeader "Entrée V."
                , viewMilestoneHeader "Sortie V."
                , viewMilestoneHeader "Entrée P."
                , viewMilestoneHeader "Sortie P."
                , viewMilestoneHeader "Fin V."
                ]
            ]
        , div [ class "h-0.5 bg-slate-800 w-full mt-1 print:bg-black" ] []
        ]
        :: List.map viewVestiairePassage cat.passages


viewMilestoneHeader : String -> Html Msg
viewMilestoneHeader label =
    div [ class "w-14 print:w-16 text-center text-[7px] font-black text-slate-400 uppercase tracking-tighter print:text-black print:text-[8px] print:font-black" ] [ text label ]


viewVestiairePassage : VestiairePassage -> Html Msg
viewVestiairePassage p =
    div [ class "group flex items-center justify-between p-6 bg-white border border-slate-100 rounded-3xl shadow-sm mb-3 hover:border-[#ea3a60] transition-colors print:shadow-none print:border-b print:border-slate-300 print:rounded-none print:p-0 print:px-4 print:mb-0 print:py-3" ]
        [ div [ class "flex-1 font-bold text-slate-800 tracking-wide print:text-[14px] print:font-black uppercase pr-4 print:text-black print:tracking-wider" ] [ text p.nom ]
        , div [ class "flex items-center gap-4 font-mono text-slate-600 print:text-black print:gap-2" ]
            [ viewMilestoneTime p.entreeV
            , viewMilestoneTime p.sortieV
            , viewMilestoneTime p.entreeP
            , viewMilestoneTime p.sortieP
            , viewMilestoneTime p.sortieVDef
            ]
        ]


viewMilestoneTime : String -> Html Msg
viewMilestoneTime time =
    div [ class "w-14 print:w-16 text-center text-sm font-bold print:text-[12px] print:font-black" ] [ text time ]


viewBuvetteCreneau : Bool -> Int -> ViewCreneau -> Html Msg
viewBuvetteCreneau shouldMask nowMinutes creneau =
    let
        timeMinutes =
            viewCreneauToMinutes creneau

        isPast =
            shouldMask && nowMinutes > (timeMinutes + 15)

        opacityClass =
            if isPast then
                " event-past"

            else if (timeMinutes - nowMinutes) <= 10 && (timeMinutes - nowMinutes) >= 0 then
                " event-imminent"

            else
                ""
    in
    div [ class ("relative group flex items-center gap-6 p-6 bg-white border-2 border-red-100 rounded-[2rem] shadow-sm overflow-hidden" ++ opacityClass) ]
        [ div [ class "absolute inset-0 bg-red-50/50 animate-pulse pointer-events-none" ] []
        , div [ class "z-10 flex-shrink-0 w-20 flex flex-col items-center justify-center border-r border-red-100 pr-6" ]
            [ div [ class "text-2xl font-black text-red-600 font-mono tracking-tight" ] [ text creneau.time ]
            , div [ class "text-2xl mt-1 print:hidden" ] [ text creneau.icon ]
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


viewBenevoleMissionItem : Bool -> Int -> Benevoles.Mission -> Html Msg
viewBenevoleMissionItem shouldMask nowMinutes mission =
    let
        timeDebut =
            mission.debut |> Maybe.withDefault "--:--"

        timeFin =
            mission.fin |> Maybe.withDefault ""

        timeMinutes =
            case mission.debut of
                Just t ->
                    case String.split ":" t of
                        [ h, m ] ->
                            (String.toInt h |> Maybe.withDefault 0) * 60 + (String.toInt m |> Maybe.withDefault 0)

                        _ ->
                            0

                Nothing ->
                    0

        isPast =
            shouldMask
                && mission.periode
                == "SAMEDI"
                && (case mission.fin of
                        Just t ->
                            case String.split ":" t of
                                [ h, m ] ->
                                    nowMinutes > ((String.toInt h |> Maybe.withDefault 0) * 60 + (String.toInt m |> Maybe.withDefault 0))

                                _ ->
                                    False

                        Nothing ->
                            False
                   )

        opacityClass =
            if isPast then
                " event-past"

            else if (timeMinutes - nowMinutes) <= 10 && (timeMinutes - nowMinutes) >= 0 then
                " event-imminent"

            else
                ""

        borderL =
            if mission.periode == "SAMEDI" then
                " border-l-[12px] border-l-[#ea3a60]"

            else
                " border-l-[12px] border-l-slate-200"

        locationBadge =
            if String.contains "REZE" (String.toUpper mission.lieu) then
                span [ class "px-2 py-0.5 bg-purple-100 text-purple-700 text-[10px] font-black rounded-md" ] [ text "📍 REZÉ" ]

            else
                span [ class "px-2 py-0.5 bg-blue-50 text-blue-600 text-[10px] font-black rounded-md" ] [ text "📍 PETIT PORT" ]
    in
    div [ class ("group flex items-center gap-4 p-4 border border-slate-100 bg-white rounded-[2rem] shadow-sm hover:shadow-md transition-all duration-300 " ++ borderL ++ opacityClass) ]
        [ div [ class "flex-shrink-0 w-16 flex flex-col items-center justify-center border-r border-slate-100 pr-4" ]
            [ div [ class "text-[10px] font-black text-slate-400 font-mono tracking-tighter" ] [ text timeDebut ]
            , div [ class "text-2xl my-1" ] [ text mission.icone ]
            , div [ class "text-[10px] font-black text-slate-400 font-mono tracking-tighter" ] [ text timeFin ]
            ]
        , div [ class "flex-1 overflow-hidden" ]
            [ div [ class "text-lg font-black leading-tight mb-0.5 text-slate-700 uppercase" ] [ text mission.mission ]
            , div [ class "text-sm font-medium text-slate-500 mb-2" ] [ text mission.description ]
            , div [ class "flex items-center gap-3" ]
                [ locationBadge
                , div [ class "text-[10px] font-bold text-slate-300 uppercase tracking-widest" ] [ text mission.periode ]
                ]
            ]
        , div [ class "flex flex-col items-center gap-2" ]
            [ button
                [ class "p-3 bg-slate-50 text-slate-400 rounded-2xl hover:bg-[#ea3a60] hover:text-white transition-all active:scale-95 group/btn"
                , onClick (ExportMission mission)
                , title "Exporter vers mon agenda"
                ]
                [ span [ class "text-lg" ] [ text "📅" ]
                ]
            , div [ class "w-1 h-8 bg-slate-100 rounded-full group-hover:bg-[#ea3a60]/20 transition-colors" ] []
            ]
        ]



-- Helper for select change


onChange : (String -> msg) -> Attribute msg
onChange tagger =
    Html.Events.on "change" (Decode.map tagger Html.Events.targetValue)


onClick : msg -> Attribute msg
onClick msg =
    Html.Events.on "click" (Decode.succeed msg)


{-| Comme onClick mais sans appeler preventDefault.
Nécessaire quand on attache un handler Elm sur un <a href="mailto:...">
car le runtime Elm bloque sinon l'ouverture du client mail.
-}
onClickPreserveDefault : msg -> Attribute msg
onClickPreserveDefault msg =
    Html.Events.custom "click"
        (Decode.succeed
            { message = msg
            , stopPropagation = False
            , preventDefault = False
            }
        )


buildMailtoUrl : List Benevoles.Mission -> String
buildMailtoUrl selectedMissions =
    let
        recipient =
            "exemple@llnp.fr"

        subject =
            "Confirmation de participation - Bénévole CDF Synchro 2026"

        missionLine m =
            "- " ++ m.mission ++ " (" ++ m.periode ++ (m.debut |> Maybe.map (\d -> " à " ++ d) |> Maybe.withDefault "") ++ ")"

        body =
            "Bonjour,\n\nJe confirme ma participation pour les missions suivantes :\n\n"
                ++ String.join "\n" (List.map missionLine selectedMissions)
                ++ "\n\nNom / Prénom : [À COMPLÉTER]\n\nCordialement."

        encode s =
            s
                |> String.replace "%" "%25"
                |> String.replace " " "%20"
                |> String.replace "\n" "%0D%0A"
                |> String.replace "é" "%C3%A9"
                |> String.replace "à" "%C3%A0"
                |> String.replace "è" "%C3%A8"
                |> String.replace "ê" "%C3%AA"
                |> String.replace "ç" "%C3%A7"
    in
    "mailto:" ++ recipient ++ "?subject=" ++ encode subject ++ "&body=" ++ encode body


viewRecapMissionItem : Benevoles.Mission -> Html Msg
viewRecapMissionItem mission =
    let
        timeRange =
            case ( mission.debut, mission.fin ) of
                ( Just s, Just e ) ->
                    s ++ " - " ++ e

                ( Just s, Nothing ) ->
                    s

                _ ->
                    ""

        locationBadge =
            if String.contains "REZE" (String.toUpper mission.lieu) then
                span [ class "px-2 py-0.5 bg-purple-100 text-purple-700 text-[10px] font-black rounded-md" ] [ text "📍 REZÉ" ]

            else
                span [ class "px-2 py-0.5 bg-blue-50 text-blue-600 text-[10px] font-black rounded-md" ] [ text "📍 PETIT PORT" ]
    in
    div [ class "flex items-center gap-4 p-4 bg-white border border-slate-100 rounded-2xl shadow-sm" ]
        [ div [ class "flex-shrink-0 w-10 h-10 bg-[#ea3a60]/10 rounded-xl flex items-center justify-center text-xl" ]
            [ text mission.icone ]
        , div [ class "flex-1 min-w-0" ]
            [ div [ class "font-black text-sm text-slate-800 uppercase truncate" ] [ text mission.mission ]
            , div [ class "flex items-center gap-2 mt-1" ]
                [ locationBadge
                , if timeRange /= "" then
                    span [ class "px-2 py-0.5 bg-slate-100 text-slate-600 text-[10px] font-black rounded-md" ] [ text ("🕒 " ++ timeRange) ]

                  else
                    text ""
                , span [ class "text-[10px] font-bold text-slate-300 uppercase tracking-widest" ] [ text mission.periode ]
                ]
            ]
        , div [ class "flex-shrink-0 w-5 h-5 bg-[#ea3a60] rounded-sm flex items-center justify-center" ]
            [ span [ class "text-white text-xs font-black" ] [ text "✓" ] ]
        ]


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Time.every 60000 Tick
        }
