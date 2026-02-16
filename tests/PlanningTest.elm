module PlanningTest exposing (..)

import Expect
import Json.Decode as Decode
import Model exposing (..)
import Set
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
        , test "getActiviteInfo for Surfaçage" <|
            \_ ->
                let
                    info =
                        getActiviteInfo (Surfacage 15)
                in
                Expect.equal info { nom = "Surfaçage", categorie = "" }
        , test "getActiviteInfo for Passage" <|
            \_ ->
                let
                    details =
                        { nom = "ZEPHYR"
                        , categorie = "ADULTE"
                        , numVestiaire = 1
                        , entreeVestiaire = { hour = 7, minute = 38 }
                        , sortieVestiaire = { hour = 7, minute = 58 }
                        , entreePiste = { hour = 8, minute = 0 }
                        , sortiePiste = { hour = 8, minute = 8 }
                        , sortieVestiaireDefinitive = { hour = 8, minute = 23 }
                        }

                    info =
                        getActiviteInfo (Passage details)
                in
                Expect.equal info { nom = "ZEPHYR", categorie = "ADULTE" }
        , test "prepareViewData transforms planning for display" <|
            \_ ->
                let
                    planning =
                        [ { heureDebut = { hour = 7, minute = 30 }, activite = Surfacage 8 }
                        , { heureDebut = { hour = 7, minute = 38 }, activite = Passage { nom = "ZEPHYR", categorie = "ADULTE", numVestiaire = 1, entreeVestiaire = { hour = 0, minute = 0 }, sortieVestiaire = { hour = 0, minute = 0 }, entreePiste = { hour = 0, minute = 0 }, sortiePiste = { hour = 0, minute = 0 }, sortieVestiaireDefinitive = { hour = 0, minute = 0 } } }
                        ]

                    viewData =
                        prepareViewData planning
                in
                Expect.equal viewData
                    [ { time = "07:30", name = "Surfaçage", category = "" }
                    , { time = "07:38", name = "ZEPHYR", category = "ADULTE" }
                    ]
        , test "can decode the first few items of the real planning.json" <|
            \_ ->
                let
                    json =
                        """{
                      "planning": [
                        { "heure": "07:30", "type": "SURFACAGE" },
                        {
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
                        }
                      ]
                    }"""

                    decoded =
                        Decode.decodeString rootDecoder json
                in
                case decoded of
                    Ok pl ->
                        Expect.equal (List.length pl) 2

                    Err err ->
                        Expect.fail (Decode.errorToString err)
        , test "getEquipes extracts unique team names" <|
            \_ ->
                let
                    planning =
                        [ { heureDebut = { hour = 7, minute = 30 }, activite = Surfacage 8 }
                        , { heureDebut = { hour = 7, minute = 38 }, activite = Passage { nom = "ZEPHYR", categorie = "ADULTE", numVestiaire = 1, entreeVestiaire = { hour = 0, minute = 0 }, sortieVestiaire = { hour = 0, minute = 0 }, entreePiste = { hour = 0, minute = 0 }, sortiePiste = { hour = 0, minute = 0 }, sortieVestiaireDefinitive = { hour = 0, minute = 0 } } }
                        , { heureDebut = { hour = 7, minute = 46 }, activite = Passage { nom = "TONNERRES", categorie = "ADULTE", numVestiaire = 2, entreeVestiaire = { hour = 0, minute = 0 }, sortieVestiaire = { hour = 0, minute = 0 }, entreePiste = { hour = 0, minute = 0 }, sortiePiste = { hour = 0, minute = 0 }, sortieVestiaireDefinitive = { hour = 0, minute = 0 } } }
                        , { heureDebut = { hour = 7, minute = 54 }, activite = Passage { nom = "ZEPHYR", categorie = "ADULTE", numVestiaire = 1, entreeVestiaire = { hour = 0, minute = 0 }, sortieVestiaire = { hour = 0, minute = 0 }, entreePiste = { hour = 0, minute = 0 }, sortiePiste = { hour = 0, minute = 0 }, sortieVestiaireDefinitive = { hour = 0, minute = 0 } } }
                        ]

                    equipes =
                        getEquipes planning
                in
                Expect.equal equipes [ "TONNERRES", "ZEPHYR" ]
        , test "getHorairesPatineur returns critical times for a team" <|
            \_ ->
                let
                    details =
                        { nom = "ZEPHYR"
                        , categorie = "ADULTE"
                        , numVestiaire = 1
                        , entreeVestiaire = { hour = 7, minute = 38 }
                        , sortieVestiaire = { hour = 7, minute = 58 }
                        , entreePiste = { hour = 8, minute = 0 }
                        , sortiePiste = { hour = 8, minute = 8 }
                        , sortieVestiaireDefinitive = { hour = 8, minute = 23 }
                        }

                    planning =
                        [ { heureDebut = { hour = 7, minute = 38 }, activite = Passage details } ]

                    horaires =
                        getHorairesPatineur "ZEPHYR" planning
                in
                Expect.equal (List.length horaires) 5
        , test "getHorairesCoach returns sorted times for multiple teams" <|
            \_ ->
                let
                    details1 =
                        { nom = "ZEPHYR"
                        , categorie = "ADULTE"
                        , numVestiaire = 1
                        , entreeVestiaire = { hour = 8, minute = 0 }
                        , sortieVestiaire = { hour = 8, minute = 20 }
                        , entreePiste = { hour = 8, minute = 22 }
                        , sortiePiste = { hour = 8, minute = 30 }
                        , sortieVestiaireDefinitive = { hour = 8, minute = 45 }
                        }

                    details2 =
                        { nom = "TONNERRES"
                        , categorie = "ADULTE"
                        , numVestiaire = 2
                        , entreeVestiaire = { hour = 7, minute = 30 }
                        , sortieVestiaire = { hour = 7, minute = 50 }
                        , entreePiste = { hour = 7, minute = 52 }
                        , sortiePiste = { hour = 8, minute = 0 }
                        , sortieVestiaireDefinitive = { hour = 8, minute = 15 }
                        }

                    planning =
                        [ { heureDebut = { hour = 8, minute = 0 }, activite = Passage details1 }
                        , { heureDebut = { hour = 7, minute = 30 }, activite = Passage details2 }
                        ]

                    coachHoraires =
                        getHorairesCoach (Set.fromList [ "ZEPHYR", "TONNERRES" ]) planning
                in
                -- Check that the first element is the earliest (7:30)
                case List.head coachHoraires of
                    Just first ->
                        Expect.equal first.time "07:30"

                    Nothing ->
                        Expect.fail "Should have results"
        , test "getHorairesVestiaire returns times for a specific vestiaire" <|
            \_ ->
                let
                    details1 =
                        { nom = "ZEPHYR"
                        , categorie = "ADULTE"
                        , numVestiaire = 1
                        , entreeVestiaire = { hour = 8, minute = 0 }
                        , sortieVestiaire = { hour = 8, minute = 20 }
                        , entreePiste = { hour = 8, minute = 22 }
                        , sortiePiste = { hour = 8, minute = 30 }
                        , sortieVestiaireDefinitive = { hour = 8, minute = 45 }
                        }

                    details2 =
                        { nom = "TONNERRES"
                        , categorie = "ADULTE"
                        , numVestiaire = 2
                        , entreeVestiaire = { hour = 7, minute = 30 }
                        , sortieVestiaire = { hour = 7, minute = 50 }
                        , entreePiste = { hour = 7, minute = 52 }
                        , sortiePiste = { hour = 8, minute = 0 }
                        , sortieVestiaireDefinitive = { hour = 8, minute = 15 }
                        }

                    planning =
                        [ { heureDebut = { hour = 8, minute = 0 }, activite = Passage details1 }
                        , { heureDebut = { hour = 7, minute = 30 }, activite = Passage details2 }
                        ]

                    vestiaireHoraires =
                        getHorairesVestiaire 1 planning
                in
                Expect.equal (List.length vestiaireHoraires) 2
        , test "estUnMomentChaud identifies rush moments" <|
            \_ ->
                Expect.all
                    [ \_ -> Expect.equal (estUnMomentChaud (Surfacage 15)) True
                    , \_ -> Expect.equal (estUnMomentChaud (Podium "P1")) True
                    , \_ -> Expect.equal (estUnMomentChaud (Pause "P" 15)) False
                    ]
                    ()
        ]



-- Sorted unique list
