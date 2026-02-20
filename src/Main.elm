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


port print : () -> Cmd msg


type alias FlagsData =
    { planning : List Creneau
    , benevoles : Maybe Benevoles.Root
    }


flagsDecoder : Decode.Decoder FlagsData
flagsDecoder =
    Decode.succeed FlagsData
        |> andMap (Decode.field "planningData" rootDecoder)
        |> andMap (Decode.maybe (Decode.field "benevolesData" Benevoles.rootDecoder))


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        decodedFlags =
            Decode.decodeValue flagsDecoder flags
                |> Result.withDefault { planning = [], benevoles = Nothing }
    in
    ( { planning = decodedFlags.planning, benevoles = decodedFlags.benevoles, contexte = Nothing, currentTime = Time.millisToPosix 0, zone = Time.utc, isDemoMode = False, demoTimeMinutes = 420 }
    , Task.perform AdjustTimeZone Time.here
    )


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

        ToggleMissionBenevole name ->
            case model.contexte of
                Just (PourBenevole set) ->
                    let
                        newSet =
                            if Set.member name set then
                                Set.remove name set

                            else
                                Set.insert name set
                    in
                    ( { model | contexte = Just (PourBenevole newSet) }, Cmd.none )

                _ ->
                    ( { model | contexte = Just (PourBenevole (Set.singleton name)) }, Cmd.none )

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
            let
                newCtx =
                    case model.contexte of
                        Just (PourVestiaire n) ->
                            if n > 0 then
                                Just (PourVestiaire 0)

                            else
                                Nothing

                        _ ->
                            Nothing
            in
            ( { model | contexte = newCtx }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.contexte of
        Nothing ->
            viewRoleSelection

        Just ctx ->
            viewStandardLayout model ctx


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
            [ roleButton "Bénévole" (PourBenevole Set.empty) "🙋" "Consultez vos missions et horaires"
            , roleButton "Patineur" (PourPatineur "") "⛸️" "Consultez vos horaires personnels"
            , roleButton "Coach" (PourCoach Set.empty) "📋" "Gérez plusieurs équipes simultanément"
            , roleButton "Vestiaire" (PourVestiaire 0) "🚪" "Impression pour les portes des vestiaires"
            , roleButton "Buvette" PourBuvette "☕" "Anticipez les rushs de surfaçage"
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

                PourPatineur _ ->
                    "context-patineur"

                PourCoach _ ->
                    "context-coach"

                PourBenevole _ ->
                    "context-benevole"

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
                    [ viewDemoMode model
                    , case ctx of
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
        PourPatineur _ ->
            div [ class "mb-8 bg-white p-6 rounded-3xl shadow-sm border border-slate-200" ]
                [ label [ class "block text-xs font-black text-slate-400 uppercase tracking-widest mb-3" ] [ text "Équipe" ]
                , div [ class "relative" ]
                    [ select
                        [ class "block w-full text-lg font-bold p-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#ea3a60] appearance-none cursor-pointer text-[#1d1d1d]"
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

        PourBenevole set ->
            let
                missions =
                    model.benevoles
                        |> Maybe.map .postesBenevoles
                        |> Maybe.withDefault []

                periodes =
                    Benevoles.getPeriodes missions
            in
            div [ class "mb-8 bg-white p-6 rounded-3xl shadow-sm border border-slate-200" ]
                [ h2 [ class "block text-xs font-black text-slate-400 uppercase tracking-widest mb-4" ] [ text "Sélectionnez vos missions" ]
                , div [ class "space-y-6" ]
                    (List.map
                        (\periode ->
                            let
                                periodeMissions =
                                    missions
                                        |> List.filter (\m -> m.periode == periode)
                            in
                            div [ class "space-y-3" ]
                                [ div [ class "flex items-center gap-3" ]
                                    [ h3 [ class "text-sm font-black text-slate-800 uppercase tracking-wider" ] [ text periode ]
                                    , div [ class "h-px bg-slate-100 flex-1" ] []
                                    ]
                                , div [ class "grid grid-cols-1 md:grid-cols-2 gap-3" ]
                                    (List.map (\m -> viewMissionCheckbox m (Set.member m.mission set)) periodeMissions)
                                ]
                        )
                        periodes
                    )
                ]


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
                        ("w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors flex-shrink-0 "
                            ++ (if isChecked then
                                    "border-[#ea3a60] bg-[#ea3a60]"

                                else
                                    "border-slate-200 bg-white"
                               )
                        )
                    ]
                    [ if isChecked then
                        span [ class "text-white text-xs" ] [ text "✓" ]

                      else
                        text ""
                    ]
                ]
            , div [ class "text-xs font-medium text-slate-500 truncate" ] [ text mission.lieu ]
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

        relevantPlanning =
            model.planning
                |> List.filter (\c -> estEncorePertinent c nowMinutes)
    in
    case ctx of
        PourPatineur "" ->
            [ div [ class "text-center py-10 text-gray-500" ] [ text "Veuillez sélectionner une équipe." ] ]

        PourPatineur teamName ->
            getHorairesPatineur teamName relevantPlanning
                |> List.map (viewCreneauWithTime nowMinutes)

        PourCoach set ->
            if Set.isEmpty set then
                [ div [ class "text-center py-10 text-gray-500" ] [ text "Veuillez sélectionner au moins une équipe." ] ]

            else
                getHorairesCoach set relevantPlanning
                    |> List.map (viewCreneauWithTime nowMinutes)

        PourBuvette ->
            getHorairesBuvette relevantPlanning
                |> List.map (viewBuvetteCreneau nowMinutes)

        PourVestiaire vNum ->
            if vNum == 0 then
                []

            else
                getHorairesVestiaireGrouped vNum model.planning
                    |> List.concatMap viewVestiaireCategorie

        PourBenevole set ->
            let
                missions =
                    model.benevoles
                        |> Maybe.map .postesBenevoles
                        |> Maybe.withDefault []
            in
            Benevoles.getMissionsSelectionnees set missions
                |> List.filter (Benevoles.estMissionPertinente nowMinutes)
                |> List.map (viewBenevoleMissionItem nowMinutes)


viewDemoMode : Model -> Html Msg
viewDemoMode model =
    div [ class "flex items-center gap-4 bg-white/5 p-2 rounded-2xl border border-white/10" ]
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


viewCreneauWithTime : Int -> ViewCreneau -> Html Msg
viewCreneauWithTime nowMinutes creneau =
    let
        timeMinutes =
            viewCreneauToMinutes creneau

        isPast =
            nowMinutes > timeMinutes
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


viewBuvetteCreneau : Int -> ViewCreneau -> Html Msg
viewBuvetteCreneau nowMinutes creneau =
    let
        timeMinutes =
            viewCreneauToMinutes creneau

        isPast =
            nowMinutes > (timeMinutes + 15)

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


viewBenevoleMissionItem : Int -> Benevoles.Mission -> Html Msg
viewBenevoleMissionItem nowMinutes mission =
    let
        timeStr =
            mission.debut |> Maybe.withDefault "--:--"

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
            mission.periode
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
    in
    div [ class ("group flex items-center gap-6 p-5 border border-slate-100 bg-white rounded-[2rem] shadow-sm hover:shadow-md transition-all duration-300 " ++ borderL ++ opacityClass) ]
        [ div [ class "flex-shrink-0 w-20 flex flex-col items-center justify-center border-r border-slate-100 pr-6" ]
            [ div [ class "text-xl font-black text-[#1d1d1d] font-mono tracking-tight" ] [ text timeStr ]
            , div [ class "text-2xl mt-1" ] [ text mission.icone ]
            ]
        , div [ class "flex-1 overflow-hidden" ]
            [ div [ class "text-lg font-black leading-tight mb-0.5 text-slate-700 uppercase" ] [ text mission.mission ]
            , div [ class "text-xs font-bold text-slate-400 uppercase tracking-widest" ] [ text (mission.periode ++ " - " ++ mission.lieu) ]
            ]
        , div [ class "w-2 h-12 bg-slate-100 rounded-full group-hover:bg-[#ea3a60]/20 transition-colors" ] []
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
        , subscriptions = \_ -> Time.every 60000 Tick
        }
