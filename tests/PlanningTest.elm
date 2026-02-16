module PlanningTest exposing (..)

import Expect
import Json.Decode as Decode
import Model exposing (..)
import Test exposing (..)


suite : Test
suite =
    describe "Planning Decoder"
        [ test "can decode a Surfaçage" <|
            \_ ->
                let
                    json =
                        """{ "heure": "07:30", "type": "SURFACAGE" }"""

                    decoded =
                        Decode.decodeString creneauDecoder json
                in
                case decoded of
                    Ok creneau ->
                        Expect.equal creneau.heureDebut { hour = 7, minute = 30 }

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , test "can decode a PASSAGE" <|
            \_ ->
                let
                    json =
                        """{
                      "heure": "07:38",
                      "type": "PASSAGE",
                      "session": "ENTRAINEMENT",
                      "equipe": "ZEPHYR",
                      "categorie": "ADULTE",
                      "vestiaire": 1,
                      "entree_v": "07:38",
                      "sortie_v": "07:58",
                      "entree_p": "08:00",
                      "sortie_p": "08:08",
                      "fin_v": "08:23"
                    }"""

                    decoded =
                        Decode.decodeString creneauDecoder json
                in
                case decoded of
                    Ok creneau ->
                        case creneau.activite of
                            Passage details ->
                                Expect.all
                                    [ \d -> Expect.equal d.nom "ZEPHYR"
                                    , \d -> Expect.equal d.numVestiaire 1
                                    , \d -> Expect.equal d.entreePiste { hour = 8, minute = 0 }
                                    ]
                                    details

                            _ ->
                                Expect.fail "Expected a Passage"

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , test "can decode the root planning object" <|
            \_ ->
                let
                    json =
                        """{
                      "nom": "COUPE DE FRANCE",
                      "lieu": "NANTES",
                      "date": "2026-04-04",
                      "planning": [
                        { "heure": "07:30", "type": "SURFACAGE" }
                      ]
                    }"""

                    decoded =
                        Decode.decodeString rootDecoder json
                in
                case decoded of
                    Ok pl ->
                        Expect.equal (List.length pl) 1

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , test "formatTime formats 7:30 correctly" <|
            \_ ->
                let
                    time =
                        { hour = 7, minute = 30 }
                in
                Expect.equal (formatTime time) "07:30"
        , test "formatTime formats 14:05 correctly" <|
            \_ ->
                let
                    time =
                        { hour = 14, minute = 5 }
                in
                Expect.equal (formatTime time) "14:05"
        ]
