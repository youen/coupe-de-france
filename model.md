module Model exposing (..)

-- 1. Gestion du temps (en minutes depuis minuit pour faciliter les calculs)
type alias Time = 
    { hour : Int
    , minute : Int 
    }

-- 2. Détails spécifiques à une équipe
type alias EquipeDetails =
    { nom : String
    , categorie : String
    , numVestiaire : Int
    , entreeVestiaire : Time
    , sortieVestiaire : Time
    , entreePiste : Time
    , sortiePiste : Time
    , sortieVestiaireDefinitive : Time
    }

-- 3. La Ressource Piste : Ce qui occupe la glace
-- Le type fort "Surfacage" ne prend plus qu'un entier pour la durée.
type Activite
    = Surfacage Int        -- Durée en minutes
    | Passage EquipeDetails
    | Pause String Int     -- Nom de la pause (ex: "Déjeuner"), Durée
    | Podium String        -- Nom du podium (ex: "Podium 1")

-- 4. Un créneau sur le planning
type alias Creneau =
    { heureDebut : Time
    , activite : Activite
    }

-- 5. Contextes d'utilisation (Tes 4 cas d'usages)
type UserContext
    = PourPatineur String      -- Nom de l'équipe
    | PourCoach (List String)  -- Liste des équipes suivies
    | PourBuvette              -- Focus sur les surfaçages et pauses
    | PourVestiaire Int        -- Focus sur un numéro de vestiaire pour impression

type alias Model =
    { planning : List Creneau
    , contexte : UserContext
    }