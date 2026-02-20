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


getPeriodes : List Mission -> List String
getPeriodes missions =
    let
        allPeriodes =
            missions
                |> List.map .periode
                |> Set.fromList
                |> Set.toList

        -- Define desired order
        order =
            [ "AMONT", "VENDREDI", "SAMEDI", "DIMANCHE" ]

        -- Helper function
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

        -- Sort function using the index in the order list
        sortFn a b =
            let
                indexA =
                    elemIndex a order |> Maybe.withDefault 99

                indexB =
                    elemIndex b order |> Maybe.withDefault 99
            in
            compare indexA indexB
    in
    allPeriodes |> List.sortWith sortFn


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
