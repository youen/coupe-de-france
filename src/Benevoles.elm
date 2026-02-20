module Benevoles exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Set


type alias Mission =
    { mission : String
    , periode : String
    , jour : Maybe String
    , description : String
    , lieu : String
    , debut : Maybe String
    , fin : Maybe String
    , icone : String
    }


type alias Root =
    { edition : String
    , postesBenevoles : List Mission
    }


missionDecoder : Decoder Mission
missionDecoder =
    Decode.succeed Mission
        |> andMap (Decode.field "mission" Decode.string)
        |> andMap (Decode.field "periode" Decode.string)
        |> andMap (Decode.field "jour" (Decode.nullable Decode.string))
        |> andMap (Decode.field "description" Decode.string)
        |> andMap (Decode.field "lieu" Decode.string)
        |> andMap (Decode.field "debut" (Decode.nullable Decode.string))
        |> andMap (Decode.field "fin" (Decode.nullable Decode.string))
        |> andMap (Decode.field "icone" Decode.string)


rootDecoder : Decoder Root
rootDecoder =
    Decode.succeed Root
        |> andMap (Decode.field "edition" Decode.string)
        |> andMap (Decode.field "postes_benevoles" (Decode.list missionDecoder))


periodeOrder : List String
periodeOrder =
    [ "AMONT", "VENDREDI", "SAMEDI", "DIMANCHE" ]


elemIndex : a -> List a -> Maybe Int
elemIndex item list =
    let
        find idx l =
            case l of
                [] ->
                    Nothing

                x :: xs ->
                    if x == item then
                        Just idx

                    else
                        find (idx + 1) xs
    in
    find 0 list


comparePeriodes : String -> String -> Order
comparePeriodes a b =
    let
        indexA =
            elemIndex a periodeOrder |> Maybe.withDefault 99

        indexB =
            elemIndex b periodeOrder |> Maybe.withDefault 99
    in
    compare indexA indexB


getPeriodes : List Mission -> List String
getPeriodes missions =
    missions
        |> List.map .periode
        |> Set.fromList
        |> Set.toList
        |> List.sortWith comparePeriodes


getMissionsSelectionnees : Set.Set String -> List Mission -> List Mission
getMissionsSelectionnees selection missions =
    let
        sortFn a b =
            case comparePeriodes a.periode b.periode of
                EQ ->
                    compare (Maybe.withDefault "24:00" a.debut) (Maybe.withDefault "24:00" b.debut)

                other ->
                    other
    in
    missions
        |> List.filter (\m -> Set.member m.mission selection)
        |> List.sortWith sortFn


estMissionPertinente : Int -> Mission -> Bool
estMissionPertinente nowMinutes mission =
    if mission.periode /= "SAMEDI" then
        True

    else
        case mission.fin of
            Just finStr ->
                case String.split ":" finStr of
                    [ h, m ] ->
                        let
                            finMinutes =
                                (String.toInt h |> Maybe.withDefault 0) * 60 + (String.toInt m |> Maybe.withDefault 0)
                        in
                        nowMinutes < finMinutes + 20

                    _ ->
                        True

            Nothing ->
                True


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
