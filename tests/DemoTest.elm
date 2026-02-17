module DemoTest exposing (..)

import Expect
import Main exposing (Msg(..))
import Model exposing (..)
import Test exposing (..)
import Time


suite : Test
suite =
    describe "US10: Time Travel Mode"
        [ test "When demo mode is OFF, view use real time" <|
            \_ ->
                let
                    realTime =
                        12 * 60

                    -- 12:00
                    model =
                        { planning = []
                        , contexte = Nothing
                        , currentTime = Time.millisToPosix 0 -- irrelevant here
                        , zone = Time.utc
                        , isDemoMode = False
                        , demoTimeMinutes = 15 * 60 -- 15:00
                        }

                    -- We'll verify this via a helper that returns effective minutes
                    effectiveMinutes =
                        getEffectiveMinutes model realTime
                in
                Expect.equal effectiveMinutes realTime
        , test "When demo mode is ON, view use demo time" <|
            \_ ->
                let
                    realTime =
                        12 * 60

                    -- 12:00
                    demoTime =
                        15 * 60

                    -- 15:00
                    model =
                        { planning = []
                        , contexte = Nothing
                        , currentTime = Time.millisToPosix 0
                        , zone = Time.utc
                        , isDemoMode = True
                        , demoTimeMinutes = demoTime
                        }

                    effectiveMinutes =
                        getEffectiveMinutes model realTime
                in
                Expect.equal effectiveMinutes demoTime
        ]
