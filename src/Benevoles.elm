module Benevoles exposing (..)

import Json.Decode as Decode exposing (Decoder)


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


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
