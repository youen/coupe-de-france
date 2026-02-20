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
                            "selectedMissions": ["MISSION 1"]
                        }
                        """

                    flagsValue =
                        Decode.decodeString Decode.value flagsJson
                            |> Result.withDefault (Encode.object [])

                    ( newModel, _ ) =
                        Main.init flagsValue
                in
                Expect.equal newModel.contexte (Just (PourBenevole (Set.singleton "MISSION 1")))
        , describe "update"
            [ test "Print message should returned in a command (non-testable directly easily, but we can check state transitions)" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , contexte = Just (PourVestiaire 1)
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        -- This is a placeholder since we can't easily test Cmd.none vs Cmd port
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
            , test "US1: ToggleMissionBenevole adds a mission to the set when not present" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , contexte = Just (PourBenevole Set.empty)
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update (Main.ToggleMissionBenevole "PREPA POCHETTES") initialModel
                    in
                    Expect.equal newModel.contexte (Just (PourBenevole (Set.singleton "PREPA POCHETTES")))
            , test "US1: ToggleMissionBenevole removes a mission from the set when present" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
                            , benevoles = Nothing
                            , contexte = Just (PourBenevole (Set.singleton "PREPA POCHETTES"))
                            , currentTime = Time.millisToPosix 0
                            , zone = Time.utc
                            , isDemoMode = False
                            , demoTimeMinutes = 420
                            }

                        ( newModel, _ ) =
                            Main.update (Main.ToggleMissionBenevole "PREPA POCHETTES") initialModel
                    in
                    Expect.equal newModel.contexte (Just (PourBenevole Set.empty))
            ]
        ]
