module BenevoleRecapTest exposing (..)

import Expect
import Main exposing (Msg(..), update)
import Model exposing (..)
import Set
import Test exposing (..)
import Time


initialModel : Model
initialModel =
    { planning = []
    , benevoles = Nothing
    , selectedTeams = Set.empty
    , selectedMissions = Set.empty
    , selectedPatineurTeam = ""
    , contexte = Just PourBenevole
    , currentTime = Time.millisToPosix 0
    , zone = Time.utc
    , isDemoMode = False
    , demoTimeMinutes = 420
    }


suite : Test
suite =
    describe "Sélection bénévole avec écran récapitulatif"
        [ test "GoToRecap depuis PourBenevole bascule le contexte vers RecapBenevole" <|
            \_ ->
                let
                    ( updatedModel, _ ) =
                        update GoToRecap initialModel
                in
                Expect.equal updatedModel.contexte (Just RecapBenevole)
        ]
