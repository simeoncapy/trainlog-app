# Général

L'application est divisée en quatre parties principales : la **carte**, la **liste des trajets**, le **classement** et les **statistiques**. Celles-ci sont accessibles via la barre de navigation en bas. D'autres fonctionnalités sont situées dans le menu principal. Vous pouvez l'ouvrir avec l'icône flottante "burger" :icon(menu): en haut à gauche.

# Carte

La carte affiche tous vos tracés de voyage. Les couleurs dépendent du mode de transport (vous pouvez changer la palette de couleurs dans les paramètres). Un trajet prévu sera affiché hachuré, et un trajet en cours sera coloré en rouge. Différents filtres sont disponibles pour afficher des trajets spécifiques, il suffit de cliquer sur le bouton en bas à droite.

De plus, trois outils sont utilisables pour gérer la carte. Le premier :icon(my_location): recentrera la carte sur votre position actuelle (si vous avez autorisé Trainlog à y accéder), et un double appui réinitialisera la valeur du zoom. La deuxième option centrera automatiquement la carte sur votre position lors de vos déplacements, appuyez sur :sym(frame_person): pour l'activer, et :sym(frame_person_off): pour la désactiver. Le dernier :icon(explore): réorientera la carte vers le Nord.

Vous pouvez cliquer sur n'importe quel tracé pour afficher une fiche résumé de votre trajet. À partir de celle-ci, vous pouvez partager, modifier, dupliquer et supprimer votre trajet. Concernant l'option de partage, vous devez l'activer dans les paramètres. Le trajet sera partagé sous forme de lien.

# Liste des trajets

Elle affichera tous vos trajets, passés et futurs (utilisez le sélecteur en haut), dans une vue paginée. Vous pouvez faire défiler le tableau horizontalement pour afficher plus d'informations sur vos trajets. Pour afficher tous les détails, cliquez sur une ligne pour faire apparaître la fiche descriptive. Si vous glissez le tableau vers le bas, cela actualisera votre liste de trajets avec le serveur.

## Ajouter un trajet - info

Sélectionnez d'abord le type de véhicule que vous avez utilisé, car cela a un impact sur la recherche de stations. Vous pouvez ensuite sélectionner les stations en saisissant leur nom. Une mini-carte vous permet de vérifier si la sélection choisie est correcte ou non. Ceci est particulièrement utile lorsqu'une grande station est divisée en différentes entités (suffixées par des lettres). Vous pouvez agrandir la mini-carte en cliquant sur :icon(fullscreen):.

Dans le cas où la station n'existe pas, vous pouvez créer une station manuelle. Pour cela, cliquez sur :sym(globe_location_pin): pour changer de mode. Saisissez ensuite le nom de la station et ses coordonnées. Si vous ne connaissez pas les coordonnées, vous pouvez également déplacer le marqueur sur la mini-carte après l'avoir agrandie.

À la fin du formulaire, vous pouvez sélectionner un ou plusieurs opérateurs pour les trajets. Ceux déjà existants apparaîtront. Dans le cas où l'opérateur n'existe pas, vous pouvez valider le champ avec "Entrée" ou une virgule pour créer un opérateur sans logo. Vous pouvez demander l'ajout du logo dans l'application sur le Discord du projet (consultez l'onglet "Trainlog").

## Ajouter un trajet - dates

Trois modes de date sont disponibles, sélectionnables en haut de l'écran :

- **Précis** : Saisissez les dates et heures exactes de départ et d'arrivée. Les deux champs incluent un sélecteur de date et un sélecteur d'heure. Le fuseau horaire est automatiquement déduit des coordonnées de la station et affiché sous chaque champ d'heure. Vous pouvez également enregistrer le retard réel en développant la section retard : saisissez le retard en minutes, ou réglez directement l'heure réelle de départ/arrivée.
- **Date** : Saisissez uniquement la date du voyage (sans heure). Vous pouvez éventuellement spécifier la durée du trajet en heures et minutes.
- **Inconnu** : Utilisez cette option lorsque vous ne connaissez pas la date exacte. Sélectionnez si le trajet est dans le passé ou le futur, et saisissez éventuellement une durée approximative.

## Ajouter un trajet - détails

Tous les champs de cette page sont facultatifs.

Vous pouvez renseigner le numéro ou le nom de la **ligne**, le **matériel** (modèle de matériel roulant), le numéro d'**immatriculation** du véhicule, votre numéro de **siège**, et une **note** en texte libre.

La section **Billet** vous permet d'enregistrer le prix du billet (avec un sélecteur de devise) et la date d'achat.

La section **Énergie** vous permet de spécifier le type de traction du véhicule : automatique, électrique ou carburant.

La section **Visibilité** contrôle qui peut voir ce trajet : privé (vous uniquement), amis uniquement, ou public.

## Ajouter un trajet - trajet

L'étape du tracé affiche une carte interactive qui calcule automatiquement l'itinéraire entre vos stations de départ et d'arrivée. La distance et la durée estimée sont affichées en haut. Pour les trajets en train, métro et tramway, vous pouvez basculer l'option **nouveau routeur** pour utiliser un moteur d'itinéraire alternatif — appuyez sur l'icône d'aide pour plus de détails. Une fois que vous êtes satisfait du tracé, appuyez sur **Valider** pour enregistrer le trajet. Vous pouvez également appuyer sur **Continuer le trajet** pour enregistrer et commencer immédiatement un nouveau trajet avec la station d'arrivée actuelle comme nouveau départ.

# Classement

La page de classement affiche le tableau des leaders de tous les utilisateurs de Trainlog pour chaque catégorie de véhicule.

# Statistiques

La page des statistiques vous permet d'explorer vos données de voyage via des graphiques et des tableaux. Utilisez le panneau de filtres en haut pour personnaliser la vue — appuyez dessus pour le développer ou le réduire.

Les filtres disponibles sont :
- **Véhicule** : le type de transport à analyser.
- **Année** : filtrer par une année spécifique, ou sélectionner "Toutes les années" pour l'historique complet. (Désactivé lorsque le type de graphique est réglé sur "Années".)
- **Type de graphique** : choisissez par quoi ventiler les données — opérateur, pays, années, matériel ou itinéraire.
- **Unité** : choisissez la métrique — nombre de trajets, distance, durée ou CO2.

Trois types de graphiques sont disponibles via le sélecteur dans le coin supérieur droit :
- **Diagramme à barres** : affiche les 10 premières entrées sous forme de barres. Une option vous permet de basculer entre les orientations horizontale et verticale.
- **Graphique en secteurs** : affiche les 10 premières entrées sous forme de graphique en secteurs (camembert).
- **Tableau** : affiche l'ensemble des données sous forme de tableau triable, avec des colonnes séparées pour les trajets passés et futurs. Une option vous permet de basculer entre le tri par valeur totale et l'ordre alphabétique.

Les trajets passés et futurs sont affichés côte à côte dans tous les types de graphiques.

# Géomémo

Géomémo est un pré-enregistreur intelligent accessible depuis le menu principal. Il vous permet d'enregistrer votre position actuelle au moment du départ et de l'arrivée, puis d'utiliser ces deux enregistrements pour créer un trajet automatiquement.

Appuyez sur le bouton **Enregistrer** pour sauvegarder un géomémo. L'application capturera vos coordonnées actuelles et l'horodatage, puis recherchera la station la plus proche dans le rayon configuré (ajustable dans les paramètres). Si plusieurs stations sont trouvées à proximité, une boîte de dialogue de sélection apparaîtra afin que vous puissiez choisir la bonne. Si aucune station n'est trouvée, le géomémo est enregistré avec un emplacement inconnu. Toutes les données sont stockées localement sur votre appareil uniquement.

Pour créer un trajet, sélectionnez exactement deux géomémos dans la liste — le premier sera traité comme le départ (marqué **D**) et le second comme l'arrivée (marqué **A**). Appuyez ensuite sur **Créer un trajet** pour ouvrir le formulaire d'ajout de trajet pré-rempli avec les emplacements et les horodatages enregistrés. Une fois le trajet enregistré, les deux géomémos sont automatiquement supprimés.

Vous pouvez supprimer des géomémos individuels en les sélectionnant et en appuyant sur **Supprimer la sélection**, ou les supprimer tous d'un coup avec **Supprimer tout**. L'ordre de tri (plus récent/plus ancien en premier) peut être modifié avec le bouton de tri.