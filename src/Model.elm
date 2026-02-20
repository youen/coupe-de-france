module Model exposing (..)

import Benevoles
import Json.Decode as Decode exposing (Decoder)
import Set
import Time



-- 1. Gestion du temps


type alias Time =
    { hour : Int
    , minute : Int
    }


type SessionType
    = Entrainement
    | Competition


type JalonType
    = HJalonEntreeVestiaire
    | HJalonEntreePiste
    | HJalonSortiePiste
    | HJalonSortieVestiaire


type alias EquipeDetails =
    { nom : String
    , categorie : String
    , session : SessionType
    , numVestiaire : Int
    , entreeVestiaire : Time
    , sortieVestiaire : Time
    , entreePiste : Time
    , sortiePiste : Time
    , sortieVestiaireDefinitive : Time
    }



-- 3. La Ressource Piste


type Activite
    = Surfacage Int
    | Passage EquipeDetails
    | Pause String Int
    | Podium String



-- 4. Un créneau sur le planning


type alias Creneau =
    { heureDebut : Time
    , activite : Activite
    }



-- 5. Contextes d'utilisation


type UserContext
    = PourPatineur
    | PourCoach
    | PourBuvette
    | PourVestiaire Int
    | PourBenevole
    | MonPlanning


type alias Model =
    { planning : List Creneau
    , benevoles : Maybe Benevoles.Root
    , selectedTeams : Set.Set String
    , selectedMissions : Set.Set String
    , selectedPatineurTeam : String
    , contexte : Maybe UserContext
    , currentTime : Time.Posix
    , zone : Time.Zone
    , isDemoMode : Bool
    , demoTimeMinutes : Int
    }


formatTime : Time -> String
formatTime { hour, minute } =
    let
        h =
            String.fromInt hour |> String.padLeft 2 '0'

        m =
            String.fromInt minute |> String.padLeft 2 '0'
    in
    h ++ ":" ++ m


type alias ActiviteInfo =
    { nom : String
    , categorie : String
    }


getActiviteInfo : Activite -> ActiviteInfo
getActiviteInfo activite =
    case activite of
        Surfacage _ ->
            { nom = "Surfaçage", categorie = "" }

        Passage details ->
            { nom = details.nom, categorie = details.categorie }

        Pause nom _ ->
            { nom = nom, categorie = "" }

        Podium nom ->
            { nom = nom, categorie = "" }


type alias ViewCreneau =
    { time : String
    , name : String
    , category : String
    , icon : String
    , flipIcon : Bool
    , session : Maybe SessionType
    , isGlissage : Bool -- True if it's EntreePiste or similar focal point
    }


type alias VestiairePassage =
    { nom : String
    , entreeV : String
    , sortieV : String
    , entreeP : String
    , sortieP : String
    , sortieVDef : String
    }


type alias VestiaireCategorie =
    { nom : String
    , passages : List VestiairePassage
    }


prepareViewData : List Creneau -> List ViewCreneau
prepareViewData pl =
    pl
        |> List.map
            (\c ->
                let
                    info =
                        getActiviteInfo c.activite

                    icon =
                        case c.activite of
                            Surfacage _ ->
                                "🧊"

                            Pause _ _ ->
                                "☕"

                            Podium _ ->
                                "🏆"

                            Passage _ ->
                                "⛸️"

                    session =
                        case c.activite of
                            Passage details ->
                                Just details.session

                            _ ->
                                Nothing
                in
                { time = formatTime c.heureDebut
                , name = info.nom
                , category = info.categorie
                , icon = icon
                , flipIcon = False
                , session = session
                , isGlissage =
                    case c.activite of
                        Passage _ ->
                            True

                        _ ->
                            False
                }
            )


getEquipes : List Creneau -> List String
getEquipes pl =
    pl
        |> List.filterMap
            (\c ->
                case c.activite of
                    Passage details ->
                        Just details.nom

                    _ ->
                        Nothing
            )
        |> Set.fromList
        |> Set.toList
        |> List.sort


getHorairesPatineur teamName pl =
    pl
        |> List.filterMap
            (\c ->
                case c.activite of
                    Passage details ->
                        if details.nom == teamName then
                            Just details

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.concatMap
            (\details ->
                [ { time = formatTime details.entreeVestiaire, name = "Entrée Vestiaire", category = "Vestiaire " ++ String.fromInt details.numVestiaire, icon = "🚪", flipIcon = False, session = Just details.session, isGlissage = False }
                , { time = formatTime details.sortieVestiaire, name = "Sortie Vestiaire", category = "", icon = "🏃", flipIcon = False, session = Just details.session, isGlissage = False }
                , { time = formatTime details.entreePiste, name = "Entrée Piste", category = details.categorie, icon = "⛸️", flipIcon = False, session = Just details.session, isGlissage = True }
                , { time = formatTime details.sortiePiste, name = "Sortie Piste", category = "", icon = "⛸️", flipIcon = True, session = Just details.session, isGlissage = False }
                , { time = formatTime details.sortieVestiaireDefinitive, name = "Sortie Vestiaire Définitive", category = "", icon = "🎒", flipIcon = False, session = Just details.session, isGlissage = False }
                ]
            )


getHorairesCoach teamNames pl =
    pl
        |> List.filterMap
            (\c ->
                case c.activite of
                    Passage details ->
                        if Set.member details.nom teamNames then
                            Just details

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.concatMap
            (\details ->
                [ { time = formatTime details.entreeVestiaire, name = details.nom ++ " - Entrée V", category = "Vestiaire " ++ String.fromInt details.numVestiaire, icon = "🚪", flipIcon = False, session = Just details.session, isGlissage = False }
                , { time = formatTime details.sortieVestiaire, name = details.nom ++ " - Sortie V", category = "", icon = "🏃", flipIcon = False, session = Just details.session, isGlissage = False }
                , { time = formatTime details.entreePiste, name = details.nom ++ " - Entrée Piste", category = details.categorie, icon = "⛸️", flipIcon = False, session = Just details.session, isGlissage = True }
                , { time = formatTime details.sortiePiste, name = details.nom ++ " - Sortie Piste", category = "", icon = "⛸️", flipIcon = True, session = Just details.session, isGlissage = False }
                , { time = formatTime details.sortieVestiaireDefinitive, name = details.nom ++ " - Sortie V Déf", category = "", icon = "🎒", flipIcon = False, session = Just details.session, isGlissage = False }
                ]
            )
        |> List.sortWith (\a b -> compareViewCreneau a b)


getHorairesVestiaire vNumber pl =
    pl
        |> List.filterMap
            (\c ->
                case c.activite of
                    Passage details ->
                        if details.numVestiaire == vNumber then
                            Just details

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.concatMap
            (\details ->
                [ { time = formatTime details.entreeVestiaire, name = details.nom ++ " - Entrée", category = details.categorie, icon = "🚪", flipIcon = False, session = Just details.session, isGlissage = False }
                , { time = formatTime details.sortieVestiaire, name = details.nom ++ " - Sortie", category = "", icon = "🏃", flipIcon = False, session = Just details.session, isGlissage = False }
                ]
            )
        |> List.sortWith (\a b -> compareViewCreneau a b)


getHorairesVestiaireGrouped : Int -> List Creneau -> List VestiaireCategorie
getHorairesVestiaireGrouped vNumber pl =
    let
        passages =
            pl
                |> List.filterMap
                    (\c ->
                        case c.activite of
                            Passage details ->
                                if details.numVestiaire == vNumber then
                                    Just details

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
                |> List.sortWith (\a b -> compare (timeToMinutes a.entreeVestiaire) (timeToMinutes b.entreeVestiaire))

        foldFn p acc =
            let
                vp =
                    { nom = p.nom
                    , entreeV = formatTime p.entreeVestiaire
                    , sortieV = formatTime p.sortieVestiaire
                    , entreeP = formatTime p.entreePiste
                    , sortieP = formatTime p.sortiePiste
                    , sortieVDef = formatTime p.sortieVestiaireDefinitive
                    }
            in
            case acc of
                [] ->
                    [ { nom = p.categorie, passages = [ vp ] } ]

                cat :: rest ->
                    if cat.nom == p.categorie then
                        { cat | passages = cat.passages ++ [ vp ] } :: rest

                    else
                        { nom = p.categorie, passages = [ vp ] } :: acc
    in
    List.foldl foldFn [] passages
        |> List.reverse


getVestiaires : List Creneau -> List Int
getVestiaires pl =
    pl
        |> List.filterMap
            (\c ->
                case c.activite of
                    Passage details ->
                        Just details.numVestiaire

                    _ ->
                        Nothing
            )
        |> Set.fromList
        |> Set.toList
        |> List.sort


estUnMomentChaud : Activite -> Bool
estUnMomentChaud activite =
    case activite of
        Surfacage _ ->
            True

        Podium _ ->
            True

        _ ->
            False


getHorairesBuvette pl =
    pl
        |> List.filter (\c -> estUnMomentChaud c.activite)
        |> prepareViewData


estEncorePertinent : Creneau -> Int -> Bool
estEncorePertinent creneau nowMinutes =
    let
        finMinutes =
            case creneau.activite of
                Passage details ->
                    timeToMinutes details.sortieVestiaireDefinitive

                Surfacage duration ->
                    timeToMinutes creneau.heureDebut + duration

                Pause _ duration ->
                    timeToMinutes creneau.heureDebut + duration

                Podium _ ->
                    timeToMinutes creneau.heureDebut + 15
    in
    nowMinutes < finMinutes + 20


posixToMinutes : Time.Zone -> Time.Posix -> Int
posixToMinutes zone posix =
    let
        h =
            Time.toHour zone posix

        m =
            Time.toMinute zone posix
    in
    h * 60 + m


getEffectiveMinutes : Model -> Int -> Int
getEffectiveMinutes model realMinutes =
    if model.isDemoMode then
        model.demoTimeMinutes

    else
        realMinutes


timeToMinutes : Time -> Int
timeToMinutes { hour, minute } =
    hour * 60 + minute


compareViewCreneau : ViewCreneau -> ViewCreneau -> Order
compareViewCreneau a b =
    compare (viewCreneauToMinutes a) (viewCreneauToMinutes b)


viewCreneauToMinutes : ViewCreneau -> Int
viewCreneauToMinutes v =
    case String.split ":" v.time of
        [ h, m ] ->
            (String.toInt h |> Maybe.withDefault 0) * 60 + (String.toInt m |> Maybe.withDefault 0)

        _ ->
            0



-- Decoder implementation


rootDecoder : Decoder (List Creneau)
rootDecoder =
    Decode.field "planning" (Decode.list creneauDecoder)


creneauDecoder : Decoder Creneau
creneauDecoder =
    Decode.map2 Creneau
        (Decode.field "heure" timeDecoder)
        activiteDecoder


timeDecoder : Decoder Time
timeDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case String.split ":" s of
                    [ h, m ] ->
                        case ( String.toInt h, String.toInt m ) of
                            ( Just hour, Just minute ) ->
                                Decode.succeed { hour = hour, minute = minute }

                            _ ->
                                Decode.fail "Invalid time format"

                    _ ->
                        Decode.fail "Invalid time format"
            )


activiteDecoder : Decoder Activite
activiteDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\type_ ->
                case type_ of
                    "SURFACAGE" ->
                        Decode.succeed (Surfacage 15)

                    "PODIUM" ->
                        Decode.succeed (Podium "Podium")

                    "PAUSE" ->
                        Decode.succeed (Pause "Pause" 30)

                    "PASSAGE" ->
                        Decode.map Passage equipeDetailsDecoder

                    _ ->
                        Decode.fail ("Unknown activity type: " ++ type_)
            )


equipeDetailsDecoder : Decoder EquipeDetails
equipeDetailsDecoder =
    Decode.succeed EquipeDetails
        |> andMap (Decode.field "equipe" Decode.string)
        |> andMap (Decode.field "categorie" Decode.string)
        |> andMap (Decode.field "session" sessionTypeDecoder)
        |> andMap (Decode.field "vestiaire" Decode.int)
        |> andMap (Decode.field "entree_v" timeDecoder)
        |> andMap (Decode.field "sortie_v" timeDecoder)
        |> andMap (Decode.field "entree_p" timeDecoder)
        |> andMap (Decode.field "sortie_p" timeDecoder)
        |> andMap (Decode.field "fin_v" timeDecoder)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


sessionTypeDecoder : Decoder SessionType
sessionTypeDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "ENTRAINEMENT" ->
                        Decode.succeed Entrainement

                    "COMPETITION" ->
                        Decode.succeed Competition

                    _ ->
                        Decode.fail ("Unknown session type: " ++ s)
            )
