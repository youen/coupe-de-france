module Model exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Set



-- 1. Gestion du temps


type alias Time =
    { hour : Int
    , minute : Int
    }



-- 2. Détails spécifiques à une équipe


type alias EquipeDetails =
    { nom : String
    , categorie : String
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
    = PourPatineur String
    | PourCoach (Set.Set String)
    | PourBuvette
    | PourVestiaire Int


type alias Model =
    { planning : List Creneau
    , contexte : UserContext
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
    }


prepareViewData : List Creneau -> List ViewCreneau
prepareViewData pl =
    pl
        |> List.map
            (\c ->
                let
                    info =
                        getActiviteInfo c.activite
                in
                { time = formatTime c.heureDebut
                , name = info.nom
                , category = info.categorie
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


getHorairesPatineur : String -> List Creneau -> List ViewCreneau
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
                [ { time = formatTime details.entreeVestiaire, name = "Entrée Vestiaire", category = "Vestiaire " ++ String.fromInt details.numVestiaire }
                , { time = formatTime details.sortieVestiaire, name = "Sortie Vestiaire", category = "" }
                , { time = formatTime details.entreePiste, name = "Entrée Piste", category = details.categorie }
                , { time = formatTime details.sortiePiste, name = "Sortie Piste", category = "" }
                , { time = formatTime details.sortieVestiaireDefinitive, name = "Sortie Vestiaire Définitive", category = "" }
                ]
            )


getHorairesCoach : Set.Set String -> List Creneau -> List ViewCreneau
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
                [ { time = formatTime details.entreeVestiaire, name = details.nom ++ " - Entrée V", category = "Vestiaire " ++ String.fromInt details.numVestiaire }
                , { time = formatTime details.sortieVestiaire, name = details.nom ++ " - Sortie V", category = "" }
                , { time = formatTime details.entreePiste, name = details.nom ++ " - Entrée Piste", category = details.categorie }
                , { time = formatTime details.sortiePiste, name = details.nom ++ " - Sortie Piste", category = "" }
                , { time = formatTime details.sortieVestiaireDefinitive, name = details.nom ++ " - Sortie V Déf", category = "" }
                ]
            )
        |> List.sortWith (\a b -> compareViewCreneau a b)


getHorairesVestiaire : Int -> List Creneau -> List ViewCreneau
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
                [ { time = formatTime details.entreeVestiaire, name = details.nom ++ " - Entrée", category = details.categorie }
                , { time = formatTime details.sortieVestiaire, name = details.nom ++ " - Sortie", category = "" }
                ]
            )
        |> List.sortWith (\a b -> compareViewCreneau a b)


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


getHorairesBuvette : List Creneau -> List ViewCreneau
getHorairesBuvette pl =
    pl
        |> List.filter (\c -> estUnMomentChaud c.activite)
        |> prepareViewData


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
    Decode.map8 EquipeDetails
        (Decode.field "equipe" Decode.string)
        (Decode.field "categorie" Decode.string)
        (Decode.field "vestiaire" Decode.int)
        (Decode.field "entree_v" timeDecoder)
        (Decode.field "sortie_v" timeDecoder)
        (Decode.field "entree_p" timeDecoder)
        (Decode.field "sortie_p" timeDecoder)
        (Decode.field "fin_v" timeDecoder)
