module BenevolesTest exposing (..)

import Benevoles exposing (..)
import Expect
import Json.Decode as Decode
import Test exposing (..)


suite : Test
suite =
    describe "Benevoles module"
        [ describe "missionDecoder"
            [ test "should decode a single mission with null fields" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "mission": "PREPA POCHETTES EQUIPES",
                                "periode": "AMONT",
                                "jour": null,
                                "description": "Préparation des documents et badges pour les équipes",
                                "lieu": "A définir",
                                "debut": null,
                                "fin": null,
                                "icone": "📂"
                            }
                            """

                        expected =
                            { mission = "PREPA POCHETTES EQUIPES"
                            , periode = "AMONT"
                            , jour = Nothing
                            , description = "Préparation des documents et badges pour les équipes"
                            , lieu = "A définir"
                            , debut = Nothing
                            , fin = Nothing
                            , icone = "📂"
                            }
                    in
                    Decode.decodeString missionDecoder json
                        |> Expect.equal (Ok expected)
            ]
        , describe "rootDecoder"
            [ test "should decode edition and list of missions" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "edition": "Coupe de France Nantes 2026",
                                "postes_benevoles": [
                                    {
                                        "mission": "PREPA POCHETTES EQUIPES",
                                        "periode": "AMONT",
                                        "jour": null,
                                        "description": "Préparation",
                                        "lieu": "A définir",
                                        "debut": null,
                                        "fin": null,
                                        "icone": "📂"
                                    }
                                ]
                            }
                            """

                        expectedMission =
                            { mission = "PREPA POCHETTES EQUIPES"
                            , periode = "AMONT"
                            , jour = Nothing
                            , description = "Préparation"
                            , lieu = "A définir"
                            , debut = Nothing
                            , fin = Nothing
                            , icone = "📂"
                            }

                        expected =
                            { edition = "Coupe de France Nantes 2026"
                            , postesBenevoles = [ expectedMission ]
                            }
                    in
                    Decode.decodeString rootDecoder json
                        |> Expect.equal (Ok expected)
            ]
        , describe "getPeriodes"
            [ test "should extract unique periods in correct order from list of missions" <|
                \_ ->
                    let
                        missions =
                            [ { mission = "M1", periode = "DIMANCHE", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            , { mission = "M2", periode = "AMONT", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            , { mission = "M3", periode = "SAMEDI", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            , { mission = "M4", periode = "VENDREDI", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            , { mission = "M5", periode = "AMONT", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            ]

                        expected =
                            [ "AMONT", "VENDREDI", "SAMEDI", "DIMANCHE" ]
                    in
                    getPeriodes missions
                        |> Expect.equal expected
            ]
        ]
