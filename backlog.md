## 🛠️ Phase 0 : Initialisation (Technique)

**US0 : Socle Technique**

* **En tant que** développeur, **je veux** mettre en place l'environnement Elm et le modèle de données de base **afin de** garantir la solidité de l'application.
* *Modèle :* Implémentation du type `Activite` (Surfacage, Passage, Pause) et de la `List Creneau`.

---

## ⛸️ Phase 1 : Consultation de base (Le MVP)

**US1 : Affichage du planning complet**

* **En tant que** visiteur, **je veux** voir la liste chronologique complète de la journée (glace et hors-glace) **afin de** connaître le déroulement global.
* *Critères :* Afficher l'heure, le nom de l'activité et la catégorie.
* *Évolution Modèle :* Ajout de fonctions de formatage d'heure (`7:30`).

**US2 : Vue Focus Patineur**

* **En tant que** patineur, **je veux** sélectionner mon équipe **afin de** ne voir que mes horaires critiques (vestiaire, piste, sortie).
* *Critères :* Un menu déroulant pour choisir l'équipe. L'écran ne montre plus que les 4 ou 5 horaires qui me concernent.
* *Évolution Modèle :* Ajout de `UserContext = PourPatineur (Maybe String)`.

---

## 📋 Phase 2 : Métiers (Coach & Organisateur)

**US3 : Tableau de bord Coach (Multi-équipes)**

* **En tant que** coach, **je veux** cocher plusieurs équipes **afin de** suivre leurs passages respectifs sans changer de vue.
* *Critères :* Liste de cases à cocher. Affichage chronologique des passages des équipes sélectionnées uniquement.
* *Évolution Modèle :* Passage à `PourCoach (Set String)` dans le contexte pour gérer la multi-sélection.

**US4 : Impression Porte de Vestiaire**

* **En tant que** bénévole logistique, **je veux** filtrer le planning par numéro de vestiaire **afin de** l'imprimer et l'afficher sur la porte.
* *Critères :* Mode "Print-friendly" (noir et blanc, gros caractères). Liste ordonnée des équipes qui vont occuper ce vestiaire précis.
* *Évolution Modèle :* Ajout de `PourVestiaire Int`.

---

## ☕ Phase 3 : Logistique de bord de piste

**US5 : Alerte Rush Buvette**

* **En tant que** responsable buvette, **je veux** voir une mise en évidence des surfaçages et des podiums **afin de** préparer les stocks avant le rush.
* *Critères :* Vue spécifique où les `Surfacage` et `Podium` sont colorés ou isolés. Compte à rebours avant le prochain surfaçage.
* *Évolution Modèle :* Ajout d'une fonction `estUnMomentChaud : Activite -> Bool`.


📋 US7.1 : Adaptation Mobile First

    En tant que utilisateur en bord de piste, je veux que les couleurs respectent le contraste #ea3a60 sur blanc afin de pouvoir lire mon horaire même avec les reflets de la glace sur mon téléphone.

    Critères : Boutons de rôle en plein écran, police Poppins taille 16px minimum (conforme au CSS du site).




## ⏱️ Phase 5 : Dynamisme et "Live"

**US8 : Rafraîchissement automatique du temps**

* **En tant qu'** utilisateur, **je veux** que l'application mette à jour le décompte avant chaque événement toutes les minutes **afin de** ne pas avoir à rafraîchir la page manuellement.
* **Critères :** Utilisation de `Time.every 60000 Tick`. Calcul du temps restant entre `maintenant` et `heure_piste`.
* **Évolution Modèle :** Ajout de `currentTime : Posix` dans le modèle.

**US9 : Cycle de vie visuel des événements (Passé/Présent/Futur)**

* **En tant qu'** utilisateur, **je veux** que les événements passés changent d'apparence avant de disparaître **afin de** distinguer visuellement ce qui est terminé de ce qui arrive.
* **Critères :** * *Futur :* Style normal (Rose `#ea3a60`).
* *Terminé :* Opacité réduite (ex: 40%) ou passage en gris pendant 20 minutes.
* *Disparition :* Masquage automatique 20 minutes après la `fin_v` (sortie vestiaire).


* **Évolution Modèle :** Logique de filtrage dans la `view` : `List.filter (\c -> estEncorePertinent c currentTime)`.

---

## 🧪 Phase 6 : Test et Simulation

**US10 : Mode "Time Travel" (Démo)**

* **En tant que** testeur/développeur, **je veux** pouvoir activer un curseur temporel **afin de** simuler l'avancement de la journée et vérifier le comportement de l'interface.
* **Critères :** * Un interrupteur "Mode Démo".
* Un slider qui modifie le `currentTime` du modèle de 07h00 à 20h00.
* Une fois activé, l'application ignore l'heure réelle du système.


* **Évolution Modèle :** ```elm
type alias Model = {
planning : List Creneau,
currentTime : Posix,
isDemoMode : Bool,
demoTimeOffset : Int -- minutes ajoutées ou heure forcée
}
```



## 🎨 Phase 7 : Identité Visuelle et Typage Métier

**US11 : Typage fort des jalons horaires**

* **En tant que** développeur, **je veux** que chaque étape (Entrée Vestiaire, Entrée Piste, etc.) soit un type de donnée distinct **afin d'** associer une logique de couleur et un pictogramme unique à chaque moment clé.
* **Critères :** Création d'un type `Jalon` :
* `EntreeVestiaire` | `EntreePiste` | `SortiePiste` | `SortieVestiaire`.


* **Évolution Modèle :** Chaque `Passage` contient une liste de `Jalons` avec leurs heures respectives.

**US12 : Code couleur différencié (Entraînement vs Compétition)**

* **En tant qu'** utilisateur, **je veux** distinguer instantanément si je regarde le planning du matin ou celui de l'après-midi **afin d'** éviter toute confusion de stress.
* **Critères :**
* **Entraînement :** Nuances de gris chaud et accents argentés (plus sobre).
* **Compétition :** Utilisation du **Rose Léo Lagrange (`#ea3a60`)** en couleur dominante.
* **Sur la glace :** C'est le point focal, la couleur est la plus saturée et le texte est en gras.



**US13 : Iconographie unifiée (Emojis métier)**

* **En tant qu'** utilisateur, **je veux** des repères visuels rapides (emojis) **afin de** comprendre la nature de l'activité sans lire le texte.
* **Référentiel partagé :**
* 🚪 `EntreeVestiaire`
* ⛸️ `EntreePiste` (Le plus mis en avant)
* 🧊 `Surfacage`
* 🏆 `Podium` / `Competition`
* ☕ `Pause` / `Buvette`
* 🎒 `SortieVestiaire`

**EPIC BENEVOLES**

US1 : Sélection personnalisée des missions

    En tant que bénévole,

    je veux pouvoir cocher mes différents postes dans la liste complète (Amont, Vendredi, Samedi, Dimanche),

    afin de générer mon planning personnel et ne voir que ce qui me concerne.

US2 : Persistance du profil (LocalStorage)

    En tant que bénévole,

    je veux que mes choix de postes soient sauvegardés localement sur mon téléphone,

    afin de retrouver mes informations instantanément à chaque ouverture de l'application.

US3 : Chronologie dynamique du "Samedi" (Live)

    En tant que bénévole travaillant le samedi,

    je veux que mes missions de cette journée affichent un décompte en temps réel et disparaissent 20 minutes après la fin,

    afin de piloter mon activité en direct pendant le pic de la compétition.

US4 : Consultation informative (Hors-Samedi)

    En tant que bénévole,

    je veux que les missions "Amont", du vendredi et du dimanche restent visibles de façon statique,

    afin de pouvoir consulter mes consignes et mes horaires sans qu'elles ne soient masquées par le flux "Live".

US5 : Alerte de lieu (Petit Port vs Rezé)

    En tant que bénévole,

    je veux qu'un code couleur et un badge 📍 distinguent clairement les deux patinoires,

    afin de ne pas me rendre sur le mauvais site géographique.

US6 : Accès aux consignes détaillées

    En tant que bénévole,

    je veux voir l'icône métier et la description de ma mission (ex: 🍿 "Prépa Pop Corn"),

    afin de savoir exactement quoi faire et où me rendre.

US7 : Mode Démo (Simulateur du Samedi)

    En tant que bénévole,

    je veux utiliser le slider "Time Travel" pour simuler spécifiquement le déroulement du samedi,

    afin de comprendre l'enchaînement de mes postes et les moments de rush.

US8 : Export d'une mission individuelle vers le calendrier

    En tant que bénévole,

    je veux pouvoir cliquer sur un bouton "Ajouter à mon agenda" sur une fiche de mission,

    afin de générer un fichier .ics contenant l'heure, le lieu et la description de ma tâche.

    Critères : Le fichier doit inclure le titre de la mission, l'adresse de la patinoire (Petit Port ou Rezé) et les notes (missions).

US9 : Export groupé de "Mon Planning"

    En tant que bénévole,

    je veux exporter l'intégralité de mes missions sélectionnées en un seul fichier calendrier,

    afin de synchroniser d'un seul coup tout mon week-end de bénévolat.

    Critères : Seules les missions cochées et sauvegardées en LocalStorage sont incluses dans l'export groupé.

US10 : Gestion des missions sans horaire fixe (Amont)

    En tant que bénévole,

    je veux que les missions "Amont" soient exportées en tant qu'événements "Journée entière" s'ils n'ont pas d'heure de début/fin,

    afin de ne pas bloquer un créneau horaire erroné mais de garder le rappel visuel dans mon agenda.
