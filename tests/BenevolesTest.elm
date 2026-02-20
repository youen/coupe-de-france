module BenevolesTest exposing (..)

import Benevoles exposing (..)
import Expect
import Json.Decode as Decode
import Set
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
        , describe "getMissionsSelectionnees"
            [ test "should return filtered and sorted missions based on selection set" <|
                \_ ->
                    let
                        missions =
                            [ { mission = "M1", periode = "DIMANCHE", jour = Just "2026-04-05", description = "", lieu = "", debut = Just "08:00", fin = Just "10:00", icone = "" }
                            , { mission = "M2", periode = "AMONT", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            , { mission = "M3", periode = "SAMEDI", jour = Just "2026-04-04", description = "", lieu = "", debut = Just "14:00", fin = Just "16:00", icone = "" }
                            , { mission = "M4", periode = "SAMEDI", jour = Just "2026-04-04", description = "", lieu = "", debut = Just "09:00", fin = Just "11:00", icone = "" }
                            ]

                        selection =
                            Set.fromList [ "M3", "M4", "M2" ]

                        expected =
                            [ { mission = "M2", periode = "AMONT", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }
                            , { mission = "M4", periode = "SAMEDI", jour = Just "2026-04-04", description = "", lieu = "", debut = Just "09:00", fin = Just "11:00", icone = "" }
                            , { mission = "M3", periode = "SAMEDI", jour = Just "2026-04-04", description = "", lieu = "", debut = Just "14:00", fin = Just "16:00", icone = "" }
                            ]
                    in
                    getMissionsSelectionnees selection missions
                        |> Expect.equal expected
            ]
        , describe "estMissionPertinente"
            [ test "US3/US4: non-Saturday missions are always relevant, Saturday missions disappear 20min after fin" <|
                \_ ->
                    let
                        missionAmont =
                            { mission = "M1", periode = "AMONT", jour = Nothing, description = "", lieu = "", debut = Nothing, fin = Nothing, icone = "" }

                        missionVendredi =
                            { mission = "M2", periode = "VENDREDI", jour = Just "2026-04-03", description = "", lieu = "", debut = Just "15:00", fin = Just "20:00", icone = "" }

                        missionSamediActive =
                            { mission = "M3", periode = "SAMEDI", jour = Just "2026-04-04", description = "", lieu = "", debut = Just "10:00", fin = Just "12:00", icone = "" }

                        missionSamediExpired =
                            { mission = "M4", periode = "SAMEDI", jour = Just "2026-04-04", description = "", lieu = "", debut = Just "10:00", fin = Just "12:00", icone = "" }

                        -- 12:15 = 12 * 60 + 15 = 735 (still relevant)
                        nowActive =
                            735

                        -- 12:21 = 12 * 60 + 21 = 741 (expired)
                        nowExpired =
                            741
                    in
                    Expect.all
                        [ \_ -> Expect.equal (estMissionPertinente nowActive missionAmont) True
                        , \_ -> Expect.equal (estMissionPertinente nowExpired missionAmont) True
                        , \_ -> Expect.equal (estMissionPertinente nowExpired missionVendredi) True
                        , \_ -> Expect.equal (estMissionPertinente nowActive missionSamediActive) True
                        , \_ -> Expect.equal (estMissionPertinente nowExpired missionSamediExpired) False
                        ]
                        ()
            ]
        ]
