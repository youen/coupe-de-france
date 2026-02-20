module TickTest exposing (..)

import Expect
import Main exposing (Msg(..), update)
import Model exposing (..)
import Set
import Test exposing (..)
import Time


suite : Test
suite =
    describe "US8: Automatic time refresh"
        [ test "Tick message updates currentTime in model" <|
            \_ ->
                let
                    initialModel =
                        { planning = []
                        , benevoles = Nothing
                        , selectedTeams = Set.empty
                        , selectedMissions = Set.empty
                        , selectedPatineurTeam = ""
                        , contexte = Nothing
                        , currentTime = Time.millisToPosix 0
                        , zone = Time.utc
                        , isDemoMode = False
                        , demoTimeMinutes = 420
                        }

                    newTime =
                        Time.millisToPosix 1000

                    ( updatedModel, _ ) =
                        update (Tick newTime) initialModel
                in
                Expect.equal updatedModel.currentTime newTime
        ]
