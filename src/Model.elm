module Model exposing (..)

import Json.Decode as Decode exposing (Decoder)



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
    | PourCoach (List String)
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
