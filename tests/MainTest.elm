module MainTest exposing (..)

import Expect
import Main
import Model exposing (UserContext(..))
import Test exposing (..)
import Time


suite : Test
suite =
    describe "Main module"
        [ describe "update"
            [ test "Print message should returned in a command (non-testable directly easily, but we can check state transitions)" <|
                \_ ->
                    let
                        initialModel =
                            { planning = []
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
            ]
        ]
