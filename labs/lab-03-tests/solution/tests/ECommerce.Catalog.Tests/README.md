# `ECommerce.Catalog.Tests` — corrigé du lab 03

Projet xUnit de tests **d'intégration** des endpoints du catalogue. Il démarre l'application
réelle en mémoire (`WebApplicationFactory`) et l'interroge par HTTP.

## Mettre en place

**1. Rendre `Program` accessible aux tests.** Les *top-level statements* de
`src/ECommerce.Catalog.Api/Program.cs` génèrent une classe `Program` **interne**. Ajoutez à la
fin du fichier :

```csharp
// Rend la classe Program accessible aux tests d'integration (WebApplicationFactory<Program>).
public partial class Program { }
```

**2. Copier le projet de tests.**

```bash
cp -r labs/lab-03-tests/solution/tests ~/lab-ecommerce/
```

**3. Référencer le projet dans la solution** (`ECommerce.slnx`), ou lancer directement :

```bash
export PATH="/usr/local/share/dotnet:$PATH"
dotnet test tests/ECommerce.Catalog.Tests/ECommerce.Catalog.Tests.csproj
```

Résultat attendu : **5 tests, 5 réussis**.

## Ce que couvrent les tests, et pourquoi

| Test | Comportement vérifié | Pourquoi il compte |
|---|---|---|
| `GetProducts_RetourneUneListe` | Chemin nominal, 200 + corps JSON | Le contrat de base du service |
| `GetProductById_IdInexistant_Retourne404` | **Cas d'erreur** | 404, pas 200 vide ni 500 — c'est ce que `Gateway` et `Ordering.Api` consomment |
| `GetProductById_IdNonEntier_...` | **Cas limite** | La contrainte de route `{id:int}` rejette avant le handler, sans exception serveur |
| `CreateProduct_PuisLecture_...` | Cycle complet création → relecture | Vérifie le `201` **et** que le `Location` retourné est réellement exploitable |
| `Health_RepondOk` | Endpoint `/health` | Les probes Kubernetes du [lab 09](../../../../lab-09-kubernetes/) en dépendent |

> **Le point pédagogique.** Quatre des cinq tests portent sur des **cas d'erreur ou limites**.
> C'est délibéré : le chemin nominal est celui qu'on teste manuellement tous les jours, donc
> celui qui casse le moins. Les régressions se cachent dans les cas que personne ne rejoue.

## Ce que ces tests ne font pas

Ils n'utilisent **pas de mock**. Les endpoints du catalogue sont volontairement minces : les
mocker reviendrait à tester le framework. Le test unitaire avec `Moq` devient pertinent dès
qu'une **règle métier** apparaît (calcul de disponibilité, remise, réservation de stock) —
c'est l'objet de la section « Pour aller plus loin » de l'[énoncé](../../README.md).
