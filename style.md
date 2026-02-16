Palette "Léo Lagrange Nantes" (La vraie)

    Couleur Principale : #ea3a60 (Ce rose-rouge punchy qu'on voit partout sur le site).

    Titres & Fond : #ffffff (Blanc).

    Navigation & Footer : #171717 (Noir profond, presque graphite).

    Police : Montserrat pour les titres et Poppins pour le corps de texte.

💻 Intégration dans ton App Elm

mode "Pink & Black". 

:root {
    --ll-pink: #ea3a60;         /* La couleur phare du site */
    --ll-pink-dark: #ea0032;    /* Pour les états hover (survol) */
    --ll-dark: #171717;         /* Utilisé pour les menus/footer */
    --ll-bg: #ffffff;           /* Fond de page blanc pur */
    --text-dark: #1d1d1d;       /* Pour le texte des paragraphes */
}

body {
    font-family: 'Poppins', sans-serif;
    color: var(--text-dark);
    background-color: var(--ll-bg);
}

h1, h2, h3 {
    font-family: 'Montserrat', sans-serif;
    color: var(--ll-pink);
    text-transform: uppercase;
}

.btn-primary {
    background-color: var(--ll-pink);
    color: white;
    border-radius: 15px; /* Vu dans le style scroll-top du site */
    padding: 10px 20px;
}

🏗️ Mise à jour du Design de l'App

    Header : Bande noire (#171717) avec le texte en blanc ou rose.

    Surfaçages : On peut les marquer avec une bordure épaisse #ea3a60 pour qu'ils flashent bien.

    Boutons de sélection : Gros boutons roses arrondis avec une ombre légère.

