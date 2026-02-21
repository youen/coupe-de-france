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
        , test "GoBack depuis RecapBenevole retourne à PourBenevole" <|
            \_ ->
                let
                    modelOnRecap =
                        { initialModel | contexte = Just RecapBenevole }

                    ( updatedModel, _ ) =
                        update GoBack modelOnRecap
                in
                Expect.equal updatedModel.contexte (Just PourBenevole)
        , test "ConfirmMissions bascule le contexte vers MonPlanning" <|
            \_ ->
                let
                    modelOnRecap =
                        { initialModel | contexte = Just RecapBenevole }

                    ( updatedModel, _ ) =
                        update ConfirmMissions modelOnRecap
                in
                Expect.equal updatedModel.contexte (Just MonPlanning)
        ]
