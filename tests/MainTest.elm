module MainTest exposing (..)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Main
import Model exposing (UserContext(..))
import Set
import Test exposing (..)
import Time


suite : Test
suite =
    describe "Main module"
        [ test "Init should decode flags with planning, benevoles and selectedMissions" <|
            \_ ->
                let
                    flagsJson =
                        """
                        {
                            "planningData": {
                                "planning": []
                            },
                            "benevolesData": {
                                "edition": "Test",
                                "postes_benevoles": []
                            },
                            "selectedMissions": ["MISSION 1"],
                            "selectedTeams": ["Equipe Test"]
                        }
                        """

                    flagsValue =
                        Decode.decodeString Decode.value flagsJson
                            |> Result.withDefault (Encode.object [])

                    ( newModel, _ ) =
                        Main.init flagsValue
                in
                Expect.equal newModel.contexte (Just MonPlanning)
        , describe "update"
            [ test "Print message should returned in a command (non-testable directly easily, but we can check state transitions)" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Just (PourVestiaire 1)
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update Main.Print initialModel
                    in
                    Expect.equal newModel.contexte (Just (PourVestiaire 1))
            , test "ResetContexte should clear context" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Just (PourVestiaire 1)
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update Main.ResetContexte initialModel
                    in
                    Expect.equal newModel.contexte Nothing
            , test "GoBack from specific vestiaire (1) should go to selection (0)" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Just (PourVestiaire 1)
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update Main.GoBack initialModel
                    in
                    Expect.equal newModel.contexte (Just (PourVestiaire 0))
            , test "GoBack from vestiaire selection (0) should go to role selection (Nothing)" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Just (PourVestiaire 0)
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update Main.GoBack initialModel
                    in
                    Expect.equal newModel.contexte Nothing
            , test "US: Can switch to MonPlanning context" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Nothing
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update (Main.SetContexte MonPlanning) initialModel
                    in
                    Expect.equal newModel.contexte (Just MonPlanning)
            , test "US: ToggleMissionBenevole updates selectedMissions in model" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Just PourBenevole
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update (Main.ToggleMissionBenevole "M1") initialModel
                    in
                    Expect.equal newModel.selectedMissions (Set.singleton "M1")
            , test "US: ToggleEquipeCoach updates selectedTeams in model" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , selectedTeams = Set.empty
                            , selectedMissions = Set.empty
                            , contexte = Just PourCoach
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update (Main.ToggleEquipeCoach "Equipe A") initialModel
                    in
                    Expect.equal newModel.selectedTeams (Set.singleton "Equipe A")
            ]
        ]
