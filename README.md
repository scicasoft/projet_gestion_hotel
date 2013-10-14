projet gestion hotel en pascal
==============================

### Énoncé

On cherche à élaborer la gestion d’un hôtel qui comporte n étages dont chacun a m chambres. Les chambres sont numérotés comme suit : les deux premiers chiffres correspondent au niveau ( 00 pour rez-de-chausée, 01 pour le premier étage, .. i pour le ième étage) suivi du rang de la chambre à chaque niveau variant de 1 à m. La catégorisation des chambres prévoit les classes économique, standing et affaires avec des tarifs respectifs de plus en plus élevés. Il est prévu d’appliquer un tarif spécial de groupe qui consiste en une réduction du tarif catégoriel. La facturation est faite sur la base unitaire de la nuitée.

La gestion consiste à réserver, supprimer une réservation, occuper et à libérer une chambre. De même, on peut prendre en compte pour un client de l’hôtel les services annexes que sont le petit déjeuner, le bar et le téléphone.

Le fichier des clients sera de type à accès direct. Un client est pris en compte dans ce fichier dés qu’il fait une réservation ; il en est supprimé s’il libère sa chambre et qu’une facture lui est établie. Cependant, un fichier annexe de fréquentation est créé pour faire une statistique mensuelle, semestrielle et annuelle.

Il s’agit de faire l’algorithme et le programme Pascal en envisageant le plus de modularité et de fonctionnalité possible.