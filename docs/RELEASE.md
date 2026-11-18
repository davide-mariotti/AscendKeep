# AscendKeep: pubblicazione su Google Play

Dove siamo arrivati e cosa manca. Aggiornato al 17/11/2026.

## Dati dell'app

| Cosa | Valore |
|---|---|
| Pacchetto | `com.ascendkeep.game` |
| Play Console | account sviluppatore `5797518783412335324`, app `4973927838018018800` |
| AdMob | app Android `ca-app-pub-5907544153918240~2079014752`, messaggio GDPR "AscendKeep GDPR" |
| Firebase | progetto `ascendkeep`, app Android con i due SHA-1 qui sotto, accesso con Google attivo |
| Chiave di caricamento | `C:\Users\mariotti\.ascendkeep\` (keystore + password), SHA-1 `B0:B3:CA:10:28:96:F7:B5:C5:B6:16:D7:01:D2:D2:C1:14:28:09:C0` |
| Chiave di firma Play | SHA-1 `87:64:1B:70:3F:20:0F:84:A7:51:FF:19:F7:DD:8C:9F:FC:14:8C:8F` (la gestisce Google) |
| Informativa privacy | https://davide-mariotti.github.io/apps/ascendkeep/privacy/ |
| Test interno | lista "AscendKeep testers", link https://play.google.com/apps/internaltest/4701188771110966876 |
| Ultima build caricata | 0.1.0, versionCode 1 (annunci di prova) |

La cartella della chiave di caricamento non è in nessuna repo: va tenuta in un backup. Senza, per aggiornare l'app bisogna chiedere a Google di cambiarla.

## Prodotti in-app

Attivi in 174 paesi, opzione di acquisto `buy` (tipo "Acquista"). In Play Console il prezzo si scrive **senza IVA**: la base è il prezzo italiano diviso 1,22.

| Prodotto | ID | Base senza IVA | Italia |
|---|---|---|---|
| Auto Restart | `com.ascendkeep.game.auto_restart` | 1,63 € | 1,99 € |
| Remove Ads | `com.ascendkeep.game.remove_ads` | 2,45 € | 2,99 € |
| Violet Core | `com.ascendkeep.game.skin_violet` | 0,81 € | 0,99 € |
| Golden Core | `com.ascendkeep.game.skin_gold` | 0,81 € | 0,99 € |

Gli ID sono quelli di `Meta.REAL_MONEY_PRODUCTS`. Il gioco conferma gli acquisti senza consumarli, quindi restano per sempre.

## Fatto

- **Gioco**: consenso UMP prima degli annunci (`scripts/Ads.gd`), "Privacy choices", "Privacy policy" e "Cloud save ID" nelle Impostazioni.
- **Scheda dello Store** EN + IT (testi in `store/listing.json`, grafica in `store/`). Categoria Strategia, contatti: email e pagina dell'app sul sito.
  Icona (la torre illustrata, dal 18/11, anche per l'italiano), immagine in primo piano e screenshot dichiarati "creati con l'AI": le illustrazioni vengono dai prompt.
- **Contenuti app**: tutte e 10 le dichiarazioni.
  - Accesso: nessuna restrizione. Il gioco parte senza login e si gioca tutto senza pagare.
  - Annunci: sì. ID pubblicità usato per annunci e antifrode.
  - IARC: PEGI 7 / ESRB Everyone (violenza fantasy contro creature, da lontano; acquisti digitali).
  - Pubblico: 13+.
  - Sicurezza dei dati: come nell'informativa (AdMob condivide posizione approssimativa, ID dispositivo, interazioni e diagnostica; Firebase tiene ID utente, email solo con Google, acquisti e progressi).
- **Pagamenti**: profilo pagamenti collegato, 4 prodotti attivi.
- **AdMob**: messaggio GDPR pubblicato (EN + IT, con "Do not consent").

Le modifiche a scheda e dichiarazioni sono salvate ma **non ancora inviate in revisione** (si inviano dalla "Panoramica della pubblicazione").

## Da fare, in ordine

1. **Build 0.1.1** (versionCode 2):
   - `USE_TEST_ADS := false` in `scripts/Ads.gd`;
   - `version/code=2` e `version/name="0.1.1"` in `export_presets.cfg`;
   - export firmato con `export-aab.sh 0.1.1`.
   Contiene anche il pulsante "Privacy policy" e l'icona illustrata (torre col nucleo azzurro), che nella 0.1.0 non ci sono:
   la 0.1.0 ha ancora l'icona a glifo, che ora resta solo sul sito.
2. Caricarla nel test interno e provarla su un telefono vero. Prima conviene aggiungere l'account come **tester di licenza**: così gli acquisti di prova non costano.
   Da controllare:
   - consenso GDPR al primo avvio;
   - un annuncio premiato;
   - un acquisto;
   - accesso con Google e salvataggio online.
3. Decidere l'iscrizione alla **commissione del 15%** (Profilo pagamenti → gruppo di account + termini). Senza, Google trattiene il 30%.
4. **Test chiuso** con almeno 12 tester per 14 giorni: lo chiede Google a ogni account personale nuovo prima della produzione.
   Insieme si inviano in revisione scheda e dichiarazioni.
5. Richiesta di accesso alla **produzione**, poi uscita.
6. Descrizione e link al sito nella pagina GitHub della repo.

## Build

Strumenti su questo PC:
- JDK 17 in `%LOCALAPPDATA%\Programs\Temurin`;
- Android SDK in `%LOCALAPPDATA%\Android\Sdk`;
- Godot 4.7.1 in `%LOCALAPPDATA%\Programs\Godot`, con i template in `%APPDATA%\Godot`.

Lo script `repos/_tools/android/export-aab.sh <versione>` fa import ed export "Android" e scrive `build/ascendkeep-<versione>.aab`.
La password della chiave la legge da `keystore.properties` e non la stampa.
Il primo import headless a volte va in crash: lo script riprova da solo.
