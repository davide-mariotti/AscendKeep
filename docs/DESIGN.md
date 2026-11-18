# AscendKeep: diario di progetto

Note di design e tecniche, in italiano. Il README per chi arriva sulla repo è [quello in radice](../README.md).

Tower defense survival minimale per mobile, fatto in Godot 4.7.

## Lore

Il mondo è stato inghiottito dal Vuoto. Ascend Keep è l'ultima struttura ancora in piedi — non un edificio, ma un'entità vivente e cosciente che ricorda ogni battaglia e ogni propria caduta. I Voidborn, creature generate dal Vuoto, sono attirati dalla sua energia e la assediano ondata dopo ondata. Ogni wave superata libera Souls; quando il Core della torre viene infine distrutto, assorbe tutte le Souls raccolte, si ricostruisce e ritorna più forte. La sua distruzione non è una fine, ma una fase del ciclo.

(Mistero non ancora rivelato al giocatore: la torre potrebbe non essere solo l'ultima difesa contro il Vuoto — potrebbe essere ciò che continua ad attirarlo, o aver avuto un ruolo nella distruzione del mondo.)

## Struttura del progetto

- `scenes/` — le `.tscn`: `Home` (hub), `Main` (la battaglia), `Enemy`, `Projectile`
- `scripts/` — la logica gameplay (`Home.gd`, `Main.gd`, `Tower.gd`, `Enemy.gd`, `Projectile.gd`, `Meta.gd`)
- `ui/` — tema grafico condiviso (`UITheme.tres`)
- `assets/icons/` — le icone dell'interfaccia, tutte da [Lucide](https://lucide.dev) 1.74.0 (ISC), la stessa libreria di tutti i miei progetti
- `assets/sprites/` — sprite di gioco (Core, Voidborn, proiettile), artwork originale
- `assets/art/` — illustrazioni più grandi: `home_splash_frames/` (i 168 frame a piena fluidità che animano lo sfondo della Home, estratti dal video), `battle-background.png` (sfondo della battaglia)
- `assets/audio/sfx/` — effetti sonori (click, acquisti, colpi, morte Voidborn, game over), CC0
- `docs/art-source/` — sorgenti non usate dal gioco: `home-splash.png`/`.mp4` (da cui vengono i frame), l'icona originale a 1024 px e la torre su sfondo trasparente
- `docs/prompts/` — prompt di generazione immagini (stile, torre, nemici, effetti, home splash, background di battaglia)

## Flusso di gioco

`Home.tscn` è la scena principale (hub). Ha una top bar (Souls, Gems, menu ☰) e una tab bar in basso con 5 tab:

1. **Battle** — sfondo animato a schermo intero (loop ambientale di ~7s a 24fps: bagliore che respira, pulviscolo che deriva) + pulsante "BATTLE" che carica `Main.tscn` (la run vera e propria)
2. **Upgrades** ("Reconstruction") — 5 potenziamenti permanenti a livelli (HP, Damage, Range, Haste, Soul Gain), pagati in Souls, sempre accessibili, non solo a fine run
3. **Skills** — un vero albero: una radice ("Awakened Core") da sbloccare prima di tutto, poi 3 rami leveled (Keen Eye, Iron Will, Soul Bond) che si possono potenziare più volte; pagati in Skill Points, una valuta pensata per arrivare solo dai boss (non esistono ancora, quindi resta a 0 per ora)
4. **Lab** — ricerca one-shot (Swift Tides), pagata in Souls, con nota che altre arriveranno
5. **Marketplace** — quattro acquisti **in soldi veri** (Auto Restart, Remove Ads, skin Core Violet/Gold), + Milestone Pass (one-shot in Souls) + due "pubblicità" ricompensate (una al giorno per +1 Skill Point, cinque al giorno per Souls); vedi sotto per lo stato reale di pubblicità e acquisti

Il menu (☰) apre un popup con Settings (SFX/Musica/Vibrazione/Auto Restart on-off), Replay Intro, Reset Progress (richiede doppio tap di conferma) e License & Credits; mentre è aperto l'icona del bottone diventa una "X" per richiuderlo.

A fine run (`Main.tscn`, torre distrutta): "Return to the Keep" torna alla Home, "Restart" ricomincia subito una nuova run. Se hai comprato Auto Restart (Marketplace) ed è attivo nelle Impostazioni, la run riparte da sola dopo qualche secondo.

## v1 — stato attuale

**Implementato**
- Torre centrale (il "Core") con HP, danno, raggio d'attacco e velocità di fuoco, spara un proiettile visibile al Voidborn più vicino nel raggio (`Tower.gd`, `Projectile.gd`); Core, Voidborn e proiettile usano artwork dedicata (`assets/sprites/`, generata da prompt in `docs/prompts/*.json`)
- Voidborn che spawnano ai bordi di un'arena circolare, camminano verso la torre e la colpiscono in mischia; alla morte lasciano un piccolo effetto di dissolvenza invece di scomparire di colpo
- Loop a ondate: numero di Voidborn e loro forza (HP/velocità/danno) crescono a ogni wave (`Main.gd`) — il numero per wave è comunque limitato a `MAX_WAVE_ENEMIES` (60) e i nemici vivi contemporaneamente a `MAX_ALIVE_ENEMIES` (40): senza questo tetto, a wave molto alte (raggiungibili in fretta testando a time_scale alto) il conteggio cresceva senza limite se il danno non teneva il passo, accumulando centinaia di nodi finché non crashava il rendering
- **Sistema Tier** (`Meta.gd`, `Main.gd`): ogni tier è un gauntlet di 100 wave, con un boss ogni 10 wave (ricompensa Souls x5 + 1 Skill Point). Il boss del **Tier 1** usa lo sprite dedicato `assets/sprites/boss-the-hollow-crown.png`; dal Tier 2 in su, finché non esiste altra art dedicata, è lo stesso Voidborn scalato ~12x HP / 2.5x danno con un glow viola invece di ciano. Raggiungere la wave 50 del tier più alto sbloccato apre il tier successivo — quelli già sbloccati restano rigiocabili per sempre, con nemici e ricompense scalati (`Meta.tier_difficulty_multiplier()` +20%/tier, `Meta.tier_reward_multiplier()` +25%/tier), fino a un tetto di 100 tier. Alla wave 50 e alla wave 100 di ogni tier si sblocca automaticamente un bonus permanente e cumulativo (+1% HP e +1% danno rispettivamente) — è lo strato di progressione che rende il gioco tendenzialmente infinito.
- Carosello Tier nel tab Battaglia: swipe a sinistra/destra (o le frecce ◀▶) per scegliere in quale tier sbloccato combattere prima di premere Battle
- Economia a Souls **per wave**: ogni wave superata libera Souls, con contatore live in HUD durante la run e un pulse visivo sull'icona alla raccolta
- 10 potenziamenti a livelli in Souls (HP, Damage, Range, Haste, Soul Gain, Critical Strike/Power, Multishot, Regeneration, Thorned Stone) con costo che scala geometricamente — le nuove statistiche di combattimento sono agganciate davvero in `Tower.gd`/`Enemy.gd` (crit chance+moltiplicatore, chance di colpire un secondo bersaglio, rigenerazione HP passiva, danno riflesso ai nemici in mischia)
- Albero Skill in `Meta.SKILL_TREE`: radice "Awakened Core" + 3 rami (Attack/Defense/HP) da **50 nodi one-time ciascuno, tutti scritti a mano** (150 nomi e frasi uniche: `Meta.SKILL_ATTACK_NODES`/`SKILL_DEFENSE_NODES`/`SKILL_HP_NODES`), ognuno sblocca il successivo nella propria catena, pagati in Skill Points, renderizzati a runtime in `Home.gd` (`_build_skill_ui()`) — il generatore templato usato inizialmente per Defense/HP è stato rimosso, non serve più
- Contatore Skill Points aggiunto anche nella top bar della Home, accanto a Souls e Gems (prima era visibile solo dentro il tab Skills)
- Lab con **103 ricerche one-shot in Souls, tutte scritte a mano**: 7 ricerche uniche (Swift Tides, Overcharge Core, Resonant Shell, Voidsight, Quickening, Auto Restart, Milestone Pass) più tre catene da 32 nodi ciascuna con nomi e frasi propri in "voce da laboratorio" (`Meta.LAB_POWER_NODES`/`LAB_GUARD_NODES`/`LAB_FLOW_NODES`), rese a runtime in `Home.gd` (`_build_lab_ui()`) — anche qui rimosso il generatore templato, non più necessario
- Nuova statistica **Defense** (`defense_pct`, riduzione percentuale del danno subito): esiste solo come bonus da Skill tree/Lab, nessun upgrade Reconstruction dedicato — non ogni statistica deve esistere in tutti e tre i sistemi
- Skills e Lab restano bloccati finché non è stato sbloccato almeno il Tier 3 (Skills) o il Tier 2 (Lab) — `Meta.skills_unlocked()`/`Meta.lab_unlocked()`, gating spostato da wave a tier perché ora un tier è un traguardo molto più grande
- Home screen con top bar (Souls, Gems, menu) e tab bar in basso (Battle / Upgrades / Skills / Lab / Marketplace)
- Menu funzionante: Replay Intro, Reset Progress (con conferma, testo in crimson durante la conferma — unico punto dove si usa il rosso, riservato al pericolo/irreversibilità), License & Credits; bottone menu che si trasforma in "X" quando il popup è aperto
- Tema UI applicato anche ai `PopupPanel` (Menu, Settings, Missioni, Milestone, Licenza): prima usavano lo stile grigio di default di Godot, ora lo stesso navy/ciano/bordo del resto della UI (`ui/UITheme.tres`)
- Icona del bottone BATTLE riallineata: Godot centra icona e testo di un Button in modo indipendente, quindi impostarli entrambi "center" li faceva sovrapporre — sistemato spostando icona+testo in un `HBoxContainer` figlio con click-passthrough, che li raggruppa davvero
- Notifica in-battaglia per gli sblocchi automatici (`Meta.notable_unlock`, ascoltata in `Main.gd`): un toast in coda per tier sbloccato, Skills/Lab sbloccati, bonus permanenti dei tier perk — gli acquisti manuali (comprare uno skill/ricerca) restano senza toast perché hanno già il loro feedback immediato (stato del pulsante + SFX)
- Scena di battaglia più dinamica: barra vita della torre non più rossa ma ciano (in linea con la palette del Core), con transizione morbida invece di scatti istantanei, un bagliore pulsante continuo, e un flash bianco + camera shake ad ogni colpo subito; anello del raggio d'attacco della torre ora ruota lentamente invece di essere un cerchio statico; i Voidborn nascono con una piccola animazione di comparsa invece di apparire di scatto; le wave boss mostrano un banner "⚠ BOSS WAVE ⚠" con shake più forte, le wave normali fanno un piccolo pulse sull'icona wave
- Schermata di fine run narrativa ("The Keep Has Fallen") con wave raggiunta, Voidborn sconfitti, Souls assorbite nella run e Souls totali
- Meta-progressione persistente su file (`user://save.json`)
- Introduzione narrativa di 3 frasi alla primissima apertura della Home (skippabile, non si ripete più, replicabile dal menu)
- Migrazione automatica dei salvataggi pre-lore (`points`/`coins` → `souls`), nessuna perdita di progressi
- Tema UI allineato alla style bible (`docs/prompts/visual-style.json`): navy/nero quasi puro, bordi ciano sottili, oro riservato al bottone BATTLE e alla valuta Souls, cremisi solo sulla barra HP
- Effetti sonori CC0 (`Audio.gd`, autoload) su click, acquisti riusciti/falliti, colpo della torre, danno subito, morte Voidborn, game over; più vibrazione mobile su colpi/acquisti/game over
- Impostazioni audio/vibrazione nel menu: SFX, Musica e Vibrazione si possono disattivare singolarmente, persistite in `Meta.gd`
- Sfondo animato a schermo intero nella tab Battle, tramite `AnimatedTexture` costruita a runtime da `Home.gd` (168 frame, 24fps nativi per un movimento fluido, ~7s), con fade a/da nero al punto di giunzione per rendere il loop invisibile; visibile solo sulla tab Battle, nascosto sulle altre
- Sfondo dedicato dietro l'arena durante la battaglia (`assets/art/battle-background.png`, `Main.tscn`); i Voidborn hanno un bagliore ciano soffuso per restare leggibili sopra lo sfondo di pietra
- Fine run: bottone "Restart" (ricomincia subito) accanto a "Return to the Keep"; se Auto Restart è stato comprato e attivo, la run riparte da sola dopo ~2.5s
- Marketplace: due ricompense "pubblicità" giornaliere (+1 Skill Point una volta al giorno, +Souls fino a 5 volte al giorno — il premio in Souls è il 15% del costo dell'upgrade più economico in Reconstruction in quel momento, quindi scala da solo con i progressi)
- **Acquisti in soldi veri** (`Meta.REAL_MONEY_PRODUCTS`, `real_purchases`, mai toccati da Reset Progress a differenza di tutto il resto): Auto Restart (spostato da Souls a IAP reale, prima era 500 Souls), Remove Ads (le ricompense pubblicitarie giornaliere vengono accreditate automaticamente ogni giorno senza dover guardare nulla), e due skin cosmetiche per il glow del Core (Violet/Gold, selezionabili una volta comprate) — vedi "Monetizzazione" sotto per lo stato reale
- Autoload `Purchases.gd` che avvolge il plugin Google Play Billing (`BillingClient`): avvia la connessione all'avvio, richiama i purchase esistenti (restore automatico), e alla conferma di un acquisto chiama `Meta.grant_real_purchase()` + acknowledge — **funziona solo su una build Android reale firmata**, nessun mock in editor (a differenza di AdMob)
- Autoload `Backend.gd` che avvolge il plugin GodotFirebase per il login anonimo: resta inerte (nessuna chiamata di rete) finché `addons/godot-firebase/.env` non viene compilato con un vero progetto Firebase — al momento è così, verificato via boot headless senza errori
- Pubblicità reali con **AdMob** (plugin `addons/admob` by Poing Studios, MIT): `Ads.gd` chiama la vera API (`MobileAds`, `RewardedAdLoader`) con gli Ad Unit ID reali del progetto — vedi "Monetizzazione" sotto per lo stato esatto e cosa manca ancora prima di andare live
- Icona app e logo "ASCEND KEEP" generati (icona: `docs/art-source/icon-1024.png`, logo: `assets/art/logo.png`). `assets/art/app-icon/make-icons.py` ne ricava l'icona del launcher e i tre livelli adattivi Android (torre, sfondo, monocromatica). L'icona "a glifo" stile Lucide esiste solo sul sito, per stare in linea con le altre app
- Missioni giornaliere (`Meta.MISSION_TEMPLATES`): 3 missioni casuali al giorno (raggiungi wave X, sconfiggi N Voidborn, guadagna N Souls, guarda N pubblicità), progresso cumulativo su tutte le run della giornata, un reroll gratuito al giorno, popup dedicato dal menu
- Milestone track (`Meta.MILESTONES`): ricompense una tantum permanenti per la wave più alta mai raggiunta (5/10/15/20/30/40/50), raddoppiate per sempre con l'acquisto one-shot "Milestone Pass" (300 Souls) — pattern free/premium senza bisogno di una UI live durante la run
- Bonus pubblicità "a streak": guardare più annunci Souls entro 30 minuti l'uno dall'altro fa crescere il moltiplicatore di ricompensa (+5% per annuncio, fino a +20%) invece di pagare sempre lo stesso importo fisso, senza alzare il tetto di 5/giorno

**Predisposto ma non attivo**
- `Meta.get_tower_evolution_stage()`: calcola uno stage 0-4 dalla somma dei livelli permanenti, pronto per far evolvere visivamente il Core sostituendo `assets/sprites/tower.png` con sprite diversi per stage; per ora resta sempre lo stesso
- `assets/sprites/boss-the-hollow-crown.png`: concept art per un futuro boss, presente ma non collegata a nessun sistema di gioco
- `Meta.gems`: campo persistito e mostrato in HUD, ma senza ancora un modo per guadagnarli (in attesa della tab Marketplace)
- `Meta.skill_points` / `Meta.add_skill_points()`: valuta dell'albero Skill, persistita e mostrata, ma senza ancora una fonte (in attesa di un sistema boss — nessun boss esiste ancora)

**Non implementato / mancante**
- Sprite statici, nessuna animazione (camminata/attacco/morte usano solo scale+fade via `Tween`, non frame di animazione)
- Nessuna musica di sottofondo (il toggle "Musica" nelle impostazioni esiste già ma non c'è ancora nessuna traccia da silenziare)
- Un solo tipo di Voidborn, nessuna elite/bioma/reliquia
- Nessun controllo touch/input attivo durante la battaglia: la torre spara da sola, non c'è interazione oltre all'osservare
- Nessun bilanciamento testato, valori (HP, danno, spawn, costi upgrade, reward per wave) sono placeholder di partenza
- Nessuna localizzazione (testi lore/upgrade in inglese, isolati in `Meta.UPGRADES`/`Meta.ONE_TIME` e nelle costanti degli script per essere facilmente estratti in futuro)

## Attenzioni note

- **Gli Ad Unit ID in `Ads.gd` sono quelli reali/di produzione**, non gli ID di test di Google. Va bene per lo sviluppo attuale (qui gira solo la Mock Ad, non contatta mai i server AdMob), ma **quando esporterai una build Android/iOS reale, prima di installarla su un device e cliccare "mostra ad", sostituisci temporaneamente gli ID con quelli di test** (`ca-app-pub-3940256099942544/...`, documentati da Google) — mostrare ad reali su un build non ancora pubblicata/approvata viola le policy AdMob e può portare a sospensione dell'account.
- Il suono del colpo della torre e il feedback aptico dei colpi subiti si ripetono ad ogni proiettile/attacco — con Haste alto o più Voidborn che attaccano insieme può risultare ripetitivo; non c'è ancora un cooldown/throttle dedicato, valutare se serve dopo un test di gioco più lungo.

## Note tecniche

- Godot 4 non ha un decoder MP4 nativo (solo Ogg Theora via `VideoStreamPlayer`), quindi il video generato dall'AI non viene letto a runtime: è stato convertito una tantum in una sequenza di 168 PNG a 150×267 (`assets/art/home_splash_frames/`) con OpenCV, mantenendo i 24fps nativi del video per un movimento fluido (niente sotto-campionamento, altrimenti l'animazione risulta scattosa), tagliando la coda nera morta e aggiungendo un fade a/da nero di ~10 frame per rendere il loop invisibile. La risoluzione è volutamente piccola per compensare l'alto numero di frame (~27MB in VRAM totali, dato che `AnimatedTexture` li tiene tutti caricati insieme, non li decodifica uno alla volta come un vero video). `Home.gd` le carica e le assembla in un `AnimatedTexture` all'avvio — se la cartella manca, lo sfondo resta semplicemente il colore di base.
- Le icone SVG di Lucide hanno `width`/`height` a 512 e tratto bianco esplicito, così Godot le rasterizza nitide; nel `.import` restano `mipmaps/generate=true` e `svg/scale=0.5`. Il pulsante del menu (solo icona, niente testo) non usa `expand_icon`: con il font Geist e il testo vuoto l'icona spariva; la dimensione la decide `icon_max_width`.
- Finestra di test in editor forzata a 480×720 (`window/size/window_width_override|height_override` in `project.godot`) solo per comodità di sviluppo — non ha effetto sull'export: su dispositivo reale si usa `window/stretch/mode="canvas_items"` + `aspect="keep"`, quindi la UI resta scalabile e proporzionata su qualsiasi schermo.

## Monetizzazione

Plugin **AdMob** (`addons/admob`, [poingstudios/godot-admob-plugin](https://github.com/poingstudios/godot-admob-plugin) v5.0.0, MIT) installato e abilitato. `Ads.gd` chiama la vera API (`MobileAds.initialize()`, `RewardedAdLoader`, `RewardedAd`) con i 2 App ID e i 4 Ad Unit ID reali del progetto (Skill Point / Souls × Android / iOS), configurati in `project.godot` (`[admob]`) e in `Ads.gd`.

**Cosa funziona già, verificato**: su questa macchina (Windows, nessun export Android/iOS) il plugin usa in automatico la sua "Mock Ad" — un overlay interattivo che simula un vero video pubblicitario (8s + bottone per chiudere e ricevere la ricompensa). Verificato: si carica e si mostra senza errori; il click finale per riscuotere la ricompensa va testato a mano nell'editor (richiede un'interazione reale, non automatizzabile).

**Cosa manca prima di poter mostrare pubblicità vere su un device**:
1. Installare Android SDK/Android Studio (per Android) e avere un Mac con Xcode (per iOS, impossibile da Windows) — su questa macchina non è installato nessuno dei due.
2. Da editor Godot: `Project → Tools → AdMob Manager` → scaricare/installare i pacchetti nativi Android e iOS (il plugin lo fa in automatico, ma richiede l'editor grafico, non è automatizzabile da riga di comando).
3. Esportare un vero APK/IPA e testare su device o emulatore reale.
4. Finché si usano gli Ad Unit ID reali (non quelli di test Google) **non mostrare ads prima della review dell'app** sugli store, altrimenti si rischia una sospensione dell'account AdMob.

Plugin **Google Play Billing** (`addons/GodotGooglePlayBilling`, [godot-sdk-integrations/godot-google-play-billing](https://github.com/godot-sdk-integrations/godot-google-play-billing) v3.3.0) installato e abilitato, con `Purchases.gd` (autoload) che lo avvolge.

**A differenza di AdMob, questo plugin non ha nessun mock in editor**: se il singleton nativo Android non è presente (cioè ovunque tranne una build Android reale), ogni chiamata non fa nulla in silenzio. Non è quindi possibile testare un acquisto vero finché non esiste una build Android firmata con i prodotti pubblicati su Play Console.

**Prima di poter vendere davvero questi 4 acquisti**, serve creare su Google Play Console (sezione "Prodotti in-app" dell'app) 4 prodotti gestiti con **esattamente** questi ID:
- `com.ascendkeep.game.auto_restart`
- `com.ascendkeep.game.remove_ads`
- `com.ascendkeep.game.skin_violet`
- `com.ascendkeep.game.skin_gold`

Plugin **GodotFirebase** (`addons/godot-firebase`, [GodotNuts/GodotFirebase](https://github.com/GodotNuts/GodotFirebase) v6.0.6) installato, abilitato e **configurato con un progetto Firebase reale** (`ascendkeep`, credenziali in `addons/godot-firebase/.env`). `Backend.gd` (autoload) fa login anonimo all'avvio e sincronizza il salvataggio con Firestore:
- `pull_save()`: al login, scarica il documento `users/{uid}`. Se esiste (cloud come sorgente di verità) sovrascrive il locale via `Meta.apply_save_data()`; se non esiste ancora (primo login) carica il salvataggio locale sul cloud con `push_save()`.
- Ogni cambiamento locale (`Meta.progress_changed`) marca una bandierina che un timer scarica al massimo ogni 15s in un unico push, per non spammare Firestore ad ogni Soul guadagnata.
- Nessun merge multi-dispositivo: si assume un dispositivo attivo alla volta.
- Regole di sicurezza in `firestore.rules` (già pubblicate sul progetto): un utente legge/scrive solo il proprio documento (`request.auth.uid == uid`).

**Verificato end-to-end contro il progetto reale** (non solo in teoria): login anonimo, push e pull di un valore reale su Firestore, confermati con un test headless dedicato — nessun mock coinvolto, a differenza di AdMob e Billing.

**Fase 2 — login con vero account Google (in corso)**: plugin **GodotGoogleSignIn** (`addons/GodotGoogleSignIn`, [NiqueWrld/GodotGoogleSignIn](https://github.com/NiqueWrld/GodotGoogleSignIn), Android nativo via Credential Manager API, nessun mock in editor come Play Billing) installato e abilitato. `Backend.gd` lo inizializza con `Firebase._config.clientId` (dal `.env`) e, al successo, scambia l'ID token Google con Firebase tramite `accounts:signInWithIdp` — riusando il nodo `Firebase.Auth` esistente (stessa gestione headers/refresh-token di ogni altra chiamata Auth, invece di duplicare la logica HTTP). UI: bottone "Sign in with Google" nel popup Impostazioni, che mostra "Android only" e resta disabilitato finché il plugin nativo o il `clientId` non ci sono.

**Ambiente Android verificato su questa macchina**: a differenza di quanto scritto prima, **Android SDK + build-tools 36/37 + un JDK sono già installati** (non serve più Android Studio da zero). È stato generato un **build Android debug reale** (`ascendkeep_debug.apk`, ~105MB) via Gradle headless, con tutti e 4 i plugin nativi (AdMob, Play Billing, Firebase/HTTPSSEClient, Google Sign-In) — **compila senza errori**. Il file non è in git (aggiunto `*.apk`/`*.aab` a `.gitignore`, sono build artifact).

SHA-1 del debug keystore locale di Godot (serve per registrare l'app Android su Firebase/Google Cloud Console):
```
DA:C4:21:36:6B:71:26:07:A9:9A:AC:E2:EA:7F:CF:56:EB:1A:96:AE
```

**Cosa manca prima che il login Google funzioni davvero**:
1. Firebase Console → Project Settings → General → "Your apps" → **aggiungi un'app Android** con package `com.ascendkeep.game` e la SHA-1 sopra (oggi il progetto ha solo l'app Web usata per Auth/Firestore via REST).
2. Firebase Console → Authentication → Sign-in method → **abilita il provider Google**. Questo crea automaticamente un OAuth **Web Client ID** — va nel campo `clientId` di `addons/godot-firebase/.env`.
3. Nessun emulatore Android disponibile su questa macchina (nessuna system image scaricata, e un emulatore grafico probabilmente non funziona in questo ambiente sandboxato) — il test finale del login va fatto su un **device Android reale**, installando l'APK con `adb install ascendkeep_debug.apk` (serve avere `platform-tools` — già presente nell'SDK — nel PATH, o il percorso completo `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`).

## Crediti

Icone da [Lucide](https://lucide.dev) (ISC), suoni da Kenney e artisticdude via OpenGameArt (tutti CC0) — vedi `assets/icons/CREDITS.md`. Gli sprite in-battaglia (Core, Voidborn, proiettile) sono artwork originale generata da prompt (`docs/prompts/*.json`).
